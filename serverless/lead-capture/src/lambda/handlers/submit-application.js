const database = require('../utils/database');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');

// Environment variables
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;
const RATE_LIMIT_TABLE = process.env.RATE_LIMIT_TABLE || 'rate-limits';
const MAX_REQUESTS_PER_HOUR = parseInt(process.env.MAX_REQUESTS_PER_HOUR) || 10;
const ALLOWED_ORIGINS = process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['*'];

const snsClient = new SNSClient({});

/**
 * Lambda handler for processing work-with-me application form submissions.
 * Validates input, applies rate limiting, logs to CloudWatch, and publishes to SNS.
 */
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  try {
    const corsHeaders = {
      'Access-Control-Allow-Origin': getAllowedOrigin(event.headers?.origin),
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

    // Validate and sanitize input
    const validationResult = validateApplicationInput(requestBody);
    if (!validationResult.isValid) {
      return createErrorResponse(400, 'VALIDATION_ERROR', validationResult.error, corsHeaders, validationResult.field);
    }

    // Get client IP for rate limiting
    const clientIP = getClientIP(event);

    // Check rate limiting
    const rateLimitCheck = await database.checkRateLimit(clientIP, MAX_REQUESTS_PER_HOUR);
    if (!rateLimitCheck.allowed) {
      return createErrorResponse(429, 'RATE_LIMIT_EXCEEDED',
        `Too many requests. Try again in ${rateLimitCheck.resetTime} minutes.`, corsHeaders);
    }

    // Log validated payload to CloudWatch before SNS publish (data safety net)
    console.log('APPLICATION_SUBMITTED:', JSON.stringify(validationResult.data));

    // Format and publish notification to SNS
    const notification = formatNotificationMessage(validationResult.data);
    try {
      await snsClient.send(new PublishCommand({
        TopicArn: SNS_TOPIC_ARN,
        Subject: notification.subject,
        Message: notification.message
      }));
    } catch (snsError) {
      console.error('SNS publish failed:', snsError);
      if (snsError.name === 'NotFoundException' || snsError.name === 'InvalidParameterException' ||
          snsError.code === 'TimeoutError' || snsError.name === 'EndpointDisabledException') {
        return createErrorResponse(502, 'NOTIFICATION_FAILED',
          'Unable to send notification. Please try again later.', corsHeaders);
      }
      return createErrorResponse(500, 'INTERNAL_ERROR',
        'An internal error occurred while processing your request', corsHeaders);
    }

    // Update rate limiting counter
    await database.updateRateLimit(clientIP);

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        message: 'Application submitted successfully'
      })
    };

  } catch (error) {
    console.error('Error processing application submission:', error);

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

// Field definitions with max lengths per design data model
const REQUIRED_FIELDS = {
  name: { maxLength: 100, label: 'Name' },
  email: { maxLength: 254, label: 'Email' },
  phone: { maxLength: 20, label: 'Phone' },
  contactTime: { maxLength: 100, label: 'Best Contact Time' },
  currentStage: { maxLength: 200, label: 'Current Stage' },
  primaryGoal: { maxLength: 500, label: 'Primary Goal' },
  timeline: { maxLength: 100, label: 'Timeline' }
};

const OPTIONAL_FIELDS = {
  businessName: { maxLength: 200, label: 'Business Name' },
  websiteUrl: { maxLength: 500, label: 'Website' }
};

/**
 * Validate and sanitize application form input.
 * Returns { isValid, data, error, field }.
 */
function validateApplicationInput(body) {
  const data = {};

  // Validate required fields
  for (const [field, config] of Object.entries(REQUIRED_FIELDS)) {
    if (!body[field] || typeof body[field] !== 'string' || body[field].trim().length === 0) {
      return { isValid: false, error: `${config.label} is required`, field };
    }

    if (field === 'email') {
      const email = body[field].toLowerCase().trim();
      if (!isValidEmail(email)) {
        return { isValid: false, error: 'Valid email address is required', field: 'email' };
      }
      data.email = email;
    } else {
      data[field] = sanitizeString(body[field], config.maxLength);
    }
  }

  // Process optional fields
  for (const [field, config] of Object.entries(OPTIONAL_FIELDS)) {
    if (body[field] && typeof body[field] === 'string' && body[field].trim().length > 0) {
      data[field] = sanitizeString(body[field], config.maxLength);
    }
  }

  return { isValid: true, data };
}

/**
 * Format a human-readable notification message from validated form data.
 */
function formatNotificationMessage(data) {
  const subject = `New Work-With-Me Application from ${data.name}`;
  const message = [
    'New Work-With-Me Application',
    '=============================',
    '',
    `Name: ${data.name}`,
    `Email: ${data.email}`,
    `Phone: ${data.phone}`,
    `Best Contact Time: ${data.contactTime}`,
    `Business Name: ${data.businessName || 'N/A'}`,
    `Website: ${data.websiteUrl || 'N/A'}`,
    '',
    `Current Stage: ${data.currentStage}`,
    `Primary Goal: ${data.primaryGoal}`,
    `Timeline: ${data.timeline}`,
    '',
    `Submitted: ${new Date().toISOString()}`
  ].join('\n');

  return { subject, message };
}

/**
 * Sanitize string input — strips HTML-unsafe chars, trims, truncates.
 */
function sanitizeString(input, maxLength = 255) {
  if (typeof input !== 'string') return '';
  return input
    .trim()
    .replace(/[<>"'&]/g, '')
    .substring(0, maxLength);
}

/**
 * Validate email format.
 */
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email) && email.length <= 254;
}

/**
 * Get client IP address from the event.
 */
function getClientIP(event) {
  return event.requestContext?.identity?.sourceIp ||
         event.headers?.['X-Forwarded-For']?.split(',')[0]?.trim() ||
         event.headers?.['X-Real-IP'] ||
         'unknown';
}

/**
 * Get allowed origin for CORS.
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
 * Create standardized error response.
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

// Export internals for testing
exports._internals = {
  validateApplicationInput,
  formatNotificationMessage,
  sanitizeString,
  isValidEmail,
  getAllowedOrigin,
  getClientIP,
  createErrorResponse,
  REQUIRED_FIELDS,
  OPTIONAL_FIELDS
};
