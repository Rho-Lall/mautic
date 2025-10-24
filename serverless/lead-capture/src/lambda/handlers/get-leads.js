const database = require('../utils/database');

// Environment variables
const API_KEY = process.env.API_KEY || 'default-api-key';
const ALLOWED_ORIGINS = process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['*'];

/**
 * Lambda handler for retrieving lead data
 * Implements authentication, pagination, and filtering for secure access
 */
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  try {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': getAllowedOrigin(event.headers.origin),
      'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
      'Access-Control-Allow-Methods': 'GET,OPTIONS',
      'Access-Control-Allow-Credentials': true,
      'Content-Type': 'application/json'
    };

    // Handle preflight OPTIONS request
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'CORS preflight successful' })
      };
    }

    // Only allow GET requests
    if (event.httpMethod !== 'GET') {
      return createErrorResponse(405, 'METHOD_NOT_ALLOWED', 'Only GET method is allowed', corsHeaders);
    }

    // Authenticate request
    const authResult = authenticateRequest(event);
    if (!authResult.isValid) {
      return createErrorResponse(401, 'UNAUTHORIZED', authResult.error, corsHeaders);
    }

    // Parse query parameters
    const queryParams = event.queryStringParameters || {};
    const {
      limit = '50',
      nextToken = null,
      email = null,
      startDate = null,
      endDate = null,
      format = 'json',
      leadId = null
    } = queryParams;

    // Validate parameters
    const validationResult = validateQueryParameters(queryParams);
    if (!validationResult.isValid) {
      return createErrorResponse(400, 'INVALID_PARAMETERS', validationResult.error, corsHeaders);
    }

    // Handle single lead retrieval
    if (leadId) {
      return await handleSingleLeadRetrieval(leadId, corsHeaders);
    }

    // Handle leads listing with filters
    const options = {
      limit: parseInt(limit),
      lastEvaluatedKey: nextToken,
      email,
      startDate,
      endDate
    };

    const result = await database.getLeads(options);

    // Format response based on requested format
    let responseBody;
    if (format === 'mautic') {
      const mauticLeads = await database.exportLeadsForMautic(options);
      responseBody = {
        success: true,
        format: 'mautic',
        data: mauticLeads,
        count: mauticLeads.length,
        nextToken: result.nextToken,
        hasMore: result.hasMore
      };
    } else {
      responseBody = {
        success: true,
        format: 'json',
        data: result.leads,
        count: result.count,
        scannedCount: result.scannedCount,
        nextToken: result.nextToken,
        hasMore: result.hasMore
      };
    }

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify(responseBody)
    };

  } catch (error) {
    console.error('Error retrieving leads:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred while retrieving leads'
        }
      })
    };
  }
};

/**
 * Handle single lead retrieval by ID
 */
async function handleSingleLeadRetrieval(leadId, corsHeaders) {
  try {
    const lead = await database.getLeadById(leadId);
    
    if (!lead) {
      return createErrorResponse(404, 'LEAD_NOT_FOUND', 'Lead not found', corsHeaders);
    }

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        data: lead
      })
    };
  } catch (error) {
    console.error('Error retrieving single lead:', error);
    throw error;
  }
}

/**
 * Authenticate API request
 */
function authenticateRequest(event) {
  // Check for API key in headers
  const apiKey = event.headers['X-Api-Key'] || event.headers['x-api-key'];
  
  if (!apiKey) {
    return {
      isValid: false,
      error: 'API key is required. Include X-Api-Key header.'
    };
  }

  if (apiKey !== API_KEY) {
    return {
      isValid: false,
      error: 'Invalid API key'
    };
  }

  return { isValid: true };
}

/**
 * Validate query parameters
 */
function validateQueryParameters(params) {
  const {
    limit,
    email,
    startDate,
    endDate,
    format,
    leadId
  } = params;

  // Validate limit
  if (limit && (isNaN(parseInt(limit)) || parseInt(limit) < 1 || parseInt(limit) > 100)) {
    return {
      isValid: false,
      error: 'Limit must be a number between 1 and 100'
    };
  }

  // Validate email format
  if (email && !isValidEmail(email)) {
    return {
      isValid: false,
      error: 'Invalid email format'
    };
  }

  // Validate date formats
  if (startDate && !isValidISODate(startDate)) {
    return {
      isValid: false,
      error: 'startDate must be in ISO 8601 format (YYYY-MM-DDTHH:mm:ss.sssZ)'
    };
  }

  if (endDate && !isValidISODate(endDate)) {
    return {
      isValid: false,
      error: 'endDate must be in ISO 8601 format (YYYY-MM-DDTHH:mm:ss.sssZ)'
    };
  }

  // Validate date range
  if (startDate && endDate && new Date(startDate) > new Date(endDate)) {
    return {
      isValid: false,
      error: 'startDate must be before endDate'
    };
  }

  // Validate format
  if (format && !['json', 'mautic'].includes(format)) {
    return {
      isValid: false,
      error: 'Format must be either "json" or "mautic"'
    };
  }

  // Validate leadId format (UUID v4)
  if (leadId && !isValidUUID(leadId)) {
    return {
      isValid: false,
      error: 'Invalid leadId format. Must be a valid UUID.'
    };
  }

  return { isValid: true };
}

/**
 * Validate email format
 */
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email) && email.length <= 254;
}

/**
 * Validate ISO date format
 */
function isValidISODate(dateString) {
  const date = new Date(dateString);
  return date instanceof Date && !isNaN(date) && date.toISOString() === dateString;
}

/**
 * Validate UUID v4 format
 */
function isValidUUID(uuid) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

/**
 * Get allowed origin for CORS
 */
function getAllowedOrigin(origin) {
  if (ALLOWED_ORIGINS.includes('*')) {
    return '*';
  }
  
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    return origin;
  }
  
  return ALLOWED_ORIGINS[0] || '*';
}

/**
 * Create standardized error response
 */
function createErrorResponse(statusCode, errorCode, message, headers, field = null) {
  const errorResponse = {
    success: false,
    error: {
      code: errorCode,
      message: message
    }
  };

  if (field) {
    errorResponse.error.field = field;
  }

  return {
    statusCode,
    headers,
    body: JSON.stringify(errorResponse)
  };
}

/**
 * Health check endpoint handler
 */
exports.healthCheck = async (event) => {
  try {
    const healthStatus = await database.healthCheck();
    
    return {
      statusCode: healthStatus.status === 'healthy' ? 200 : 503,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(healthStatus)
    };
  } catch (error) {
    console.error('Health check failed:', error);
    
    return {
      statusCode: 503,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error.message
      })
    };
  }
};

/**
 * Get leads count endpoint handler
 */
exports.getLeadsCount = async (event) => {
  try {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': getAllowedOrigin(event.headers.origin),
      'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
      'Access-Control-Allow-Methods': 'GET,OPTIONS',
      'Access-Control-Allow-Credentials': true,
      'Content-Type': 'application/json'
    };

    // Handle preflight OPTIONS request
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'CORS preflight successful' })
      };
    }

    // Authenticate request
    const authResult = authenticateRequest(event);
    if (!authResult.isValid) {
      return createErrorResponse(401, 'UNAUTHORIZED', authResult.error, corsHeaders);
    }

    // Parse query parameters
    const queryParams = event.queryStringParameters || {};
    const { startDate = null, endDate = null } = queryParams;

    // Validate date parameters
    if (startDate && !isValidISODate(startDate)) {
      return createErrorResponse(400, 'INVALID_PARAMETERS', 
        'startDate must be in ISO 8601 format', corsHeaders);
    }

    if (endDate && !isValidISODate(endDate)) {
      return createErrorResponse(400, 'INVALID_PARAMETERS', 
        'endDate must be in ISO 8601 format', corsHeaders);
    }

    const count = await database.getLeadsCount(startDate, endDate);

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        count,
        startDate,
        endDate,
        timestamp: new Date().toISOString()
      })
    };

  } catch (error) {
    console.error('Error getting leads count:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred while getting leads count'
        }
      })
    };
  }
};