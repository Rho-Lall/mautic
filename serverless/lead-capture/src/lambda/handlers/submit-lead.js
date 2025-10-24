const { v4: uuidv4 } = require('uuid');
const database = require('../utils/database');

// Environment variables
const LEADS_TABLE = process.env.LEADS_TABLE || 'serverless-leads';
const RATE_LIMIT_TABLE = process.env.RATE_LIMIT_TABLE || 'rate-limits';
const MAX_REQUESTS_PER_HOUR = parseInt(process.env.MAX_REQUESTS_PER_HOUR) || 10;
const ALLOWED_ORIGINS = process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['*'];

/**
 * Lambda handler for processing lead form submissions
 * Implements validation, rate limiting, and secure data storage
 */
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  try {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': getAllowedOrigin(event.headers.origin),
      'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
      'Access-Control-Allow-Methods': 'POST,OPTIONS',
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

    // Only allow POST requests
    if (event.httpMethod !== 'POST') {
      return createErrorResponse(405, 'METHOD_NOT_ALLOWED', 'Only POST method is allowed', corsHeaders);
    }

    // Parse request body
    let requestBody;
    try {
      requestBody = JSON.parse(event.body || '{}');
    } catch (error) {
      return createErrorResponse(400, 'INVALID_JSON', 'Invalid JSON in request body', corsHeaders);
    }

    // Get client IP for rate limiting
    const clientIP = getClientIP(event);
    
    // Check rate limiting
    const rateLimitCheck = await database.checkRateLimit(clientIP, MAX_REQUESTS_PER_HOUR);
    if (!rateLimitCheck.allowed) {
      return createErrorResponse(429, 'RATE_LIMIT_EXCEEDED', 
        `Too many requests. Try again in ${rateLimitCheck.resetTime} minutes.`, corsHeaders);
    }

    // Validate and sanitize input
    const validationResult = validateAndSanitizeInput(requestBody);
    if (!validationResult.isValid) {
      return createErrorResponse(400, 'VALIDATION_ERROR', validationResult.error, corsHeaders, validationResult.field);
    }

    // Check for spam indicators
    const spamCheck = detectSpam(validationResult.data, event);
    if (spamCheck.isSpam) {
      console.log('Spam detected:', spamCheck.reason);
      return createErrorResponse(400, 'SPAM_DETECTED', 'Submission rejected due to spam indicators', corsHeaders);
    }

    // Create lead record
    const leadData = {
      leadId: uuidv4(),
      timestamp: new Date().toISOString(),
      source: event.headers.origin || 'unknown',
      contact: validationResult.data.contact,
      customFields: validationResult.data.customFields || {},
      metadata: {
        userAgent: event.headers['User-Agent'] || 'unknown',
        ipAddress: clientIP,
        referrer: event.headers.referer || event.headers.Referer || 'direct'
      }
    };

    // Store lead in DynamoDB
    await database.storeLead(leadData);

    // Update rate limiting counter
    await database.updateRateLimit(clientIP);

    // Return success response
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        message: 'Lead submitted successfully',
        leadId: leadData.leadId
      })
    };

  } catch (error) {
    console.error('Error processing lead submission:', error);
    
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
          message: 'An internal error occurred while processing your request'
        }
      })
    };
  }
};

/**
 * Validate and sanitize input data
 */
function validateAndSanitizeInput(data) {
  const errors = [];
  const sanitized = {
    contact: {},
    customFields: {}
  };

  // Required fields validation
  if (!data.name || typeof data.name !== 'string' || data.name.trim().length === 0) {
    return { isValid: false, error: 'Name is required', field: 'name' };
  }
  if (!data.email || typeof data.email !== 'string' || !isValidEmail(data.email)) {
    return { isValid: false, error: 'Valid email address is required', field: 'email' };
  }

  // Sanitize and validate name
  sanitized.contact.name = sanitizeString(data.name, 100);
  if (sanitized.contact.name.length < 2) {
    return { isValid: false, error: 'Name must be at least 2 characters long', field: 'name' };
  }

  // Sanitize and validate email
  sanitized.contact.email = data.email.toLowerCase().trim();
  if (!isValidEmail(sanitized.contact.email)) {
    return { isValid: false, error: 'Invalid email format', field: 'email' };
  }

  // Optional fields
  if (data.company) {
    sanitized.contact.company = sanitizeString(data.company, 200);
  }
  if (data.phone) {
    sanitized.contact.phone = sanitizePhone(data.phone);
  }

  // Custom fields (for future Mautic compatibility)
  if (data.customFields && typeof data.customFields === 'object') {
    for (const [key, value] of Object.entries(data.customFields)) {
      if (typeof key === 'string' && key.length <= 50 && typeof value === 'string') {
        sanitized.customFields[sanitizeString(key, 50)] = sanitizeString(value, 500);
      }
    }
  }

  return { isValid: true, data: sanitized };
}

/**
 * Sanitize string input
 */
function sanitizeString(input, maxLength = 255) {
  if (typeof input !== 'string') return '';
  
  return input
    .trim()
    .replace(/[<>\"'&]/g, '') // Remove potentially dangerous characters
    .substring(0, maxLength);
}

/**
 * Sanitize phone number
 */
function sanitizePhone(phone) {
  if (typeof phone !== 'string') return '';
  
  // Keep only digits, spaces, hyphens, parentheses, and plus sign
  return phone.replace(/[^0-9\s\-\(\)\+]/g, '').substring(0, 20);
}

/**
 * Validate email format
 */
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email) && email.length <= 254;
}

/**
 * Detect spam indicators
 */
function detectSpam(data, event) {
  const spamIndicators = [];

  // Check for suspicious patterns in name
  if (data.contact.name) {
    const name = data.contact.name.toLowerCase();
    const suspiciousPatterns = ['test', 'spam', 'bot', 'fake', 'admin', 'root'];
    if (suspiciousPatterns.some(pattern => name.includes(pattern))) {
      spamIndicators.push('suspicious_name');
    }
  }

  // Check for suspicious email domains
  if (data.contact.email) {
    const emailDomain = data.contact.email.split('@')[1];
    const suspiciousDomains = ['tempmail.org', '10minutemail.com', 'guerrillamail.com'];
    if (suspiciousDomains.includes(emailDomain)) {
      spamIndicators.push('suspicious_email_domain');
    }
  }

  // Check for missing User-Agent (potential bot)
  if (!event.headers['User-Agent']) {
    spamIndicators.push('missing_user_agent');
  }

  // Check for too many custom fields (potential spam)
  if (Object.keys(data.customFields || {}).length > 10) {
    spamIndicators.push('too_many_fields');
  }

  return {
    isSpam: spamIndicators.length >= 2, // Require at least 2 indicators
    reason: spamIndicators.join(', ')
  };
}



/**
 * Get client IP address
 */
function getClientIP(event) {
  return event.requestContext?.identity?.sourceIp || 
         event.headers['X-Forwarded-For']?.split(',')[0]?.trim() ||
         event.headers['X-Real-IP'] ||
         'unknown';
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