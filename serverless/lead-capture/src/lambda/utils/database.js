const AWS = require('aws-sdk');

// Initialize DynamoDB client
const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_REGION || 'us-east-1'
});

// Table names from environment variables
const LEADS_TABLE = process.env.LEADS_TABLE || 'serverless-leads';
const RATE_LIMIT_TABLE = process.env.RATE_LIMIT_TABLE || 'rate-limits';

/**
 * Database operations for the serverless lead capture system
 * Provides abstraction layer for DynamoDB operations with error handling
 */
class DatabaseService {
  
  /**
   * Store a new lead in the database
   * @param {Object} leadData - The lead data to store
   * @returns {Promise<Object>} - Success confirmation with leadId
   */
  async storeLead(leadData) {
    const params = {
      TableName: LEADS_TABLE,
      Item: {
        ...leadData,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      ConditionExpression: 'attribute_not_exists(leadId)' // Prevent duplicates
    };

    try {
      await dynamodb.put(params).promise();
      console.log('Lead stored successfully:', leadData.leadId);
      
      return {
        success: true,
        leadId: leadData.leadId,
        message: 'Lead stored successfully'
      };
    } catch (error) {
      if (error.code === 'ConditionalCheckFailedException') {
        throw new Error('Duplicate lead submission detected');
      }
      
      console.error('Error storing lead:', error);
      throw new Error(`Failed to store lead: ${error.message}`);
    }
  }

  /**
   * Retrieve a lead by ID
   * @param {string} leadId - The lead ID to retrieve
   * @returns {Promise<Object|null>} - The lead data or null if not found
   */
  async getLeadById(leadId) {
    const params = {
      TableName: LEADS_TABLE,
      Key: { leadId }
    };

    try {
      const result = await dynamodb.get(params).promise();
      return result.Item || null;
    } catch (error) {
      console.error('Error retrieving lead:', error);
      throw new Error(`Failed to retrieve lead: ${error.message}`);
    }
  }

  /**
   * Retrieve leads with pagination and filtering
   * @param {Object} options - Query options
   * @param {number} options.limit - Maximum number of items to return
   * @param {string} options.lastEvaluatedKey - Pagination token
   * @param {string} options.email - Filter by email address
   * @param {string} options.startDate - Filter by start date (ISO string)
   * @param {string} options.endDate - Filter by end date (ISO string)
   * @returns {Promise<Object>} - Paginated results with leads and pagination info
   */
  async getLeads(options = {}) {
    const {
      limit = 50,
      lastEvaluatedKey = null,
      email = null,
      startDate = null,
      endDate = null
    } = options;

    let params = {
      TableName: LEADS_TABLE,
      Limit: Math.min(limit, 100), // Cap at 100 items per request
      ScanIndexForward: false // Most recent first
    };

    // Add pagination token if provided
    if (lastEvaluatedKey) {
      params.ExclusiveStartKey = JSON.parse(Buffer.from(lastEvaluatedKey, 'base64').toString());
    }

    // If filtering by email, use GSI
    if (email) {
      params.IndexName = 'email-index';
      params.KeyConditionExpression = 'email = :email';
      params.ExpressionAttributeValues = {
        ':email': email.toLowerCase()
      };
      
      // Use Query instead of Scan for GSI
      return this._queryWithFilters(params, startDate, endDate);
    }

    // For general queries, use Scan with filters
    return this._scanWithFilters(params, startDate, endDate);
  }

  /**
   * Query leads using GSI with additional filters
   * @private
   */
  async _queryWithFilters(params, startDate, endDate) {
    // Add date range filters if provided
    if (startDate || endDate) {
      const filterExpressions = [];
      
      if (startDate) {
        filterExpressions.push('#timestamp >= :startDate');
        params.ExpressionAttributeValues[':startDate'] = startDate;
      }
      
      if (endDate) {
        filterExpressions.push('#timestamp <= :endDate');
        params.ExpressionAttributeValues[':endDate'] = endDate;
      }
      
      if (filterExpressions.length > 0) {
        params.FilterExpression = filterExpressions.join(' AND ');
        params.ExpressionAttributeNames = {
          '#timestamp': 'timestamp'
        };
      }
    }

    try {
      const result = await dynamodb.query(params).promise();
      return this._formatLeadsResponse(result);
    } catch (error) {
      console.error('Error querying leads:', error);
      throw new Error(`Failed to query leads: ${error.message}`);
    }
  }

  /**
   * Scan leads with filters
   * @private
   */
  async _scanWithFilters(params, startDate, endDate) {
    // Add date range filters if provided
    if (startDate || endDate) {
      const filterExpressions = [];
      params.ExpressionAttributeValues = params.ExpressionAttributeValues || {};
      
      if (startDate) {
        filterExpressions.push('#timestamp >= :startDate');
        params.ExpressionAttributeValues[':startDate'] = startDate;
      }
      
      if (endDate) {
        filterExpressions.push('#timestamp <= :endDate');
        params.ExpressionAttributeValues[':endDate'] = endDate;
      }
      
      if (filterExpressions.length > 0) {
        params.FilterExpression = filterExpressions.join(' AND ');
        params.ExpressionAttributeNames = {
          '#timestamp': 'timestamp'
        };
      }
    }

    try {
      const result = await dynamodb.scan(params).promise();
      return this._formatLeadsResponse(result);
    } catch (error) {
      console.error('Error scanning leads:', error);
      throw new Error(`Failed to scan leads: ${error.message}`);
    }
  }

  /**
   * Format leads response with pagination info
   * @private
   */
  _formatLeadsResponse(result) {
    const nextToken = result.LastEvaluatedKey 
      ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
      : null;

    return {
      leads: result.Items || [],
      count: result.Count || 0,
      scannedCount: result.ScannedCount || 0,
      nextToken,
      hasMore: !!result.LastEvaluatedKey
    };
  }

  /**
   * Check if an email already exists in the database
   * @param {string} email - Email address to check
   * @returns {Promise<boolean>} - True if email exists
   */
  async emailExists(email) {
    const params = {
      TableName: LEADS_TABLE,
      IndexName: 'email-index',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email.toLowerCase()
      },
      Limit: 1,
      Select: 'COUNT'
    };

    try {
      const result = await dynamodb.query(params).promise();
      return result.Count > 0;
    } catch (error) {
      console.error('Error checking email existence:', error);
      return false; // Assume doesn't exist if check fails
    }
  }

  /**
   * Update lead data (for future use)
   * @param {string} leadId - The lead ID to update
   * @param {Object} updateData - Data to update
   * @returns {Promise<Object>} - Updated lead data
   */
  async updateLead(leadId, updateData) {
    // Build update expression dynamically
    const updateExpressions = [];
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};

    // Always update the updatedAt timestamp
    updateData.updatedAt = new Date().toISOString();

    Object.keys(updateData).forEach((key, index) => {
      const attributeName = `#attr${index}`;
      const attributeValue = `:val${index}`;
      
      updateExpressions.push(`${attributeName} = ${attributeValue}`);
      expressionAttributeNames[attributeName] = key;
      expressionAttributeValues[attributeValue] = updateData[key];
    });

    const params = {
      TableName: LEADS_TABLE,
      Key: { leadId },
      UpdateExpression: `SET ${updateExpressions.join(', ')}`,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW',
      ConditionExpression: 'attribute_exists(leadId)' // Ensure lead exists
    };

    try {
      const result = await dynamodb.update(params).promise();
      return result.Attributes;
    } catch (error) {
      if (error.code === 'ConditionalCheckFailedException') {
        throw new Error('Lead not found');
      }
      
      console.error('Error updating lead:', error);
      throw new Error(`Failed to update lead: ${error.message}`);
    }
  }

  /**
   * Delete a lead (for GDPR compliance)
   * @param {string} leadId - The lead ID to delete
   * @returns {Promise<boolean>} - True if deleted successfully
   */
  async deleteLead(leadId) {
    const params = {
      TableName: LEADS_TABLE,
      Key: { leadId },
      ConditionExpression: 'attribute_exists(leadId)'
    };

    try {
      await dynamodb.delete(params).promise();
      console.log('Lead deleted successfully:', leadId);
      return true;
    } catch (error) {
      if (error.code === 'ConditionalCheckFailedException') {
        throw new Error('Lead not found');
      }
      
      console.error('Error deleting lead:', error);
      throw new Error(`Failed to delete lead: ${error.message}`);
    }
  }

  /**
   * Get leads count by date range
   * @param {string} startDate - Start date (ISO string)
   * @param {string} endDate - End date (ISO string)
   * @returns {Promise<number>} - Count of leads in date range
   */
  async getLeadsCount(startDate = null, endDate = null) {
    let params = {
      TableName: LEADS_TABLE,
      Select: 'COUNT'
    };

    // Add date range filters if provided
    if (startDate || endDate) {
      const filterExpressions = [];
      params.ExpressionAttributeValues = {};
      
      if (startDate) {
        filterExpressions.push('#timestamp >= :startDate');
        params.ExpressionAttributeValues[':startDate'] = startDate;
      }
      
      if (endDate) {
        filterExpressions.push('#timestamp <= :endDate');
        params.ExpressionAttributeValues[':endDate'] = endDate;
      }
      
      if (filterExpressions.length > 0) {
        params.FilterExpression = filterExpressions.join(' AND ');
        params.ExpressionAttributeNames = {
          '#timestamp': 'timestamp'
        };
      }
    }

    try {
      const result = await dynamodb.scan(params).promise();
      return result.Count || 0;
    } catch (error) {
      console.error('Error getting leads count:', error);
      throw new Error(`Failed to get leads count: ${error.message}`);
    }
  }

  /**
   * Export leads in Mautic-compatible format
   * @param {Object} options - Export options
   * @returns {Promise<Array>} - Array of leads in Mautic format
   */
  async exportLeadsForMautic(options = {}) {
    const leadsResult = await this.getLeads(options);
    
    return leadsResult.leads.map(lead => ({
      // Mautic standard fields
      email: lead.contact.email,
      firstname: lead.contact.name.split(' ')[0],
      lastname: lead.contact.name.split(' ').slice(1).join(' ') || '',
      company: lead.contact.company || '',
      phone: lead.contact.phone || '',
      
      // Custom fields with mautic_ prefix
      ...Object.keys(lead.customFields || {}).reduce((acc, key) => {
        acc[`mautic_${key}`] = lead.customFields[key];
        return acc;
      }, {}),
      
      // Metadata
      source: lead.source,
      created_at: lead.timestamp,
      ip_address: lead.metadata?.ipAddress,
      user_agent: lead.metadata?.userAgent,
      referrer: lead.metadata?.referrer
    }));
  }

  /**
   * Rate limiting operations
   */

  /**
   * Check rate limit for a client
   * @param {string} clientIP - Client IP address
   * @param {number} maxRequests - Maximum requests per hour
   * @returns {Promise<Object>} - Rate limit status
   */
  async checkRateLimit(clientIP, maxRequests = 10) {
    const currentHour = Math.floor(Date.now() / (1000 * 60 * 60));
    const rateLimitKey = `${clientIP}-${currentHour}`;

    try {
      const result = await dynamodb.get({
        TableName: RATE_LIMIT_TABLE,
        Key: { rateLimitKey }
      }).promise();

      const currentCount = result.Item ? result.Item.requestCount : 0;
      const allowed = currentCount < maxRequests;
      
      return {
        allowed,
        currentCount,
        maxRequests,
        resetTime: 60 - (Math.floor(Date.now() / (1000 * 60)) % 60) // Minutes until next hour
      };
    } catch (error) {
      console.error('Error checking rate limit:', error);
      // Allow request if rate limit check fails
      return { allowed: true, currentCount: 0, maxRequests, resetTime: 60 };
    }
  }

  /**
   * Update rate limiting counter
   * @param {string} clientIP - Client IP address
   * @returns {Promise<void>}
   */
  async updateRateLimit(clientIP) {
    const currentHour = Math.floor(Date.now() / (1000 * 60 * 60));
    const rateLimitKey = `${clientIP}-${currentHour}`;
    const ttl = Math.floor(Date.now() / 1000) + (2 * 60 * 60); // TTL 2 hours from now

    try {
      await dynamodb.update({
        TableName: RATE_LIMIT_TABLE,
        Key: { rateLimitKey },
        UpdateExpression: 'ADD requestCount :inc SET #ttl = :ttl',
        ExpressionAttributeNames: {
          '#ttl': 'ttl'
        },
        ExpressionAttributeValues: {
          ':inc': 1,
          ':ttl': ttl
        }
      }).promise();
    } catch (error) {
      console.error('Error updating rate limit:', error);
      // Don't fail the request if rate limit update fails
    }
  }

  /**
   * Health check for database connectivity
   * @returns {Promise<Object>} - Health status
   */
  async healthCheck() {
    try {
      // Simple operation to test connectivity
      await dynamodb.describeTable({ TableName: LEADS_TABLE }).promise();
      
      return {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        tables: {
          leads: 'accessible',
          rateLimit: 'accessible'
        }
      };
    } catch (error) {
      console.error('Database health check failed:', error);
      
      return {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error.message
      };
    }
  }
}

// Export singleton instance
module.exports = new DatabaseService();