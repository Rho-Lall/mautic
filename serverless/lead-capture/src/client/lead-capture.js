/**
 * Serverless Lead Capture Form
 * A vanilla JavaScript form component that embeds into any website
 * Designed for GitHub Pages and static sites
 */

(function() {
    'use strict';

    // Configuration defaults
    const DEFAULT_CONFIG = {
        apiEndpoint: '',
        fields: 'name,email,details',
        title: 'Get in Touch',
        submitText: 'Submit',
        successMessage: 'Thank you! We\'ll be in touch soon.',
        errorMessage: 'Something went wrong. Please try again.',
        theme: 'light',
        width: 'full',
        position: 'inline',
        // Advanced configuration options
        requiredFields: 'name,email', // Override which fields are required
        fieldLabels: '', // Custom field labels (JSON string)
        fieldPlaceholders: '', // Custom field placeholders (JSON string)
        validationMessages: '', // Custom validation messages (JSON string)
        submitOnEnter: true, // Allow form submission with Enter key
        showRequiredIndicator: true, // Show * for required fields
        autoFocus: false, // Auto-focus first field
        resetOnSuccess: true, // Reset form after successful submission
        allowedDomains: '', // Comma-separated list of allowed domains for CORS
        apiKey: '', // Optional API key for authentication
        customCss: '', // Custom CSS classes to add
        debugMode: false // Enable console logging for debugging
    };

    // Form validation rules - Mautic compatible field definitions
    const VALIDATION_RULES = {
        // Standard contact fields (Mautic compatible)
        name: {
            required: true,
            minLength: 2,
            maxLength: 50,
            pattern: /^[a-zA-Z\s\-'\.]+$/,
            message: 'Please enter a valid name (2-50 characters, letters only)',
            mauticField: 'firstname' // Maps to Mautic firstname field
        },
        lastname: {
            required: false,
            minLength: 2,
            maxLength: 50,
            pattern: /^[a-zA-Z\s\-'\.]+$/,
            message: 'Please enter a valid last name',
            mauticField: 'lastname'
        },
        email: {
            required: true,
            pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
            message: 'Please enter a valid email address',
            mauticField: 'email'
        },
        company: {
            required: false,
            maxLength: 100,
            message: 'Company name must be less than 100 characters',
            mauticField: 'company'
        },
        phone: {
            required: false,
            pattern: /^[\+]?[1-9][\d]{0,15}$/,
            message: 'Please enter a valid phone number',
            mauticField: 'phone'
        },
        // Custom fields
        details: {
            required: false,
            maxLength: 500,
            message: 'Details must be less than 500 characters',
            mauticField: 'details', // Custom field in Mautic
            fieldType: 'textarea'
        },
        website: {
            required: false,
            pattern: /^https?:\/\/.+/,
            message: 'Please enter a valid website URL',
            mauticField: 'website'
        },
        jobtitle: {
            required: false,
            maxLength: 100,
            message: 'Job title must be less than 100 characters',
            mauticField: 'position'
        },
        // Lead source tracking
        leadsource: {
            required: false,
            maxLength: 100,
            message: 'Lead source identifier',
            mauticField: 'leadsource',
            fieldType: 'hidden'
        },
        // Custom Mautic fields (can be extended)
        industry: {
            required: false,
            maxLength: 50,
            message: 'Industry must be less than 50 characters',
            mauticField: 'industry',
            fieldType: 'select',
            options: ['Technology', 'Healthcare', 'Finance', 'Education', 'Other']
        },
        budget: {
            required: false,
            pattern: /^\d+$/,
            message: 'Please enter a valid budget amount',
            mauticField: 'budget',
            fieldType: 'number'
        }
    };

    /**
     * LeadCaptureForm Class
     */
    class LeadCaptureForm {
        constructor(container, config = {}) {
            this.container = container;
            this.config = { ...DEFAULT_CONFIG, ...config };
            this.isSubmitting = false;
            
            this.init();
        }

        /**
         * Initialize the form
         */
        init() {
            this.validateConfig();
            this.render();
            this.attachEventListeners();
        }

        /**
         * Validate configuration
         */
        validateConfig() {
            if (!this.config.apiEndpoint) {
                console.error('LeadCaptureForm: API endpoint is required');
                return;
            }

            // Parse fields from comma-separated string
            if (typeof this.config.fields === 'string') {
                this.config.fields = this.config.fields.split(',').map(f => f.trim());
            }

            // Parse required fields
            if (typeof this.config.requiredFields === 'string') {
                this.config.requiredFields = this.config.requiredFields.split(',').map(f => f.trim());
            }

            // Ensure email is always required
            if (!this.config.requiredFields.includes('email')) {
                this.config.requiredFields.push('email');
            }

            // Ensure required fields are included in fields list
            this.config.requiredFields.forEach(field => {
                if (!this.config.fields.includes(field)) {
                    this.config.fields.push(field);
                }
            });

            // Parse JSON configurations
            this.parseJsonConfig('fieldLabels');
            this.parseJsonConfig('fieldPlaceholders');
            this.parseJsonConfig('validationMessages');

            // Parse allowed domains
            if (typeof this.config.allowedDomains === 'string' && this.config.allowedDomains) {
                this.config.allowedDomains = this.config.allowedDomains.split(',').map(d => d.trim());
            }

            // Debug logging
            if (this.config.debugMode) {
                console.log('LeadCaptureForm Config:', this.config);
            }
        }

        /**
         * Parse JSON configuration strings
         */
        parseJsonConfig(configKey) {
            if (typeof this.config[configKey] === 'string' && this.config[configKey]) {
                try {
                    this.config[configKey] = JSON.parse(this.config[configKey]);
                } catch (e) {
                    console.warn(`LeadCaptureForm: Invalid JSON for ${configKey}:`, this.config[configKey]);
                    this.config[configKey] = {};
                }
            } else {
                this.config[configKey] = {};
            }
        }

        /**
         * Render the form HTML
         */
        render() {
            const formId = 'lead-capture-form-' + Math.random().toString(36).substr(2, 9);
            
            const formHTML = `
                <div class="lead-capture-wrapper" data-theme="${this.config.theme}" data-width="${this.config.width}">
                    <form id="${formId}" class="lead-capture-form" novalidate>
                        <div class="form-header">
                            <h3 class="form-title">${this.escapeHtml(this.config.title)}</h3>
                        </div>
                        
                        <div class="form-body">
                            ${this.renderFields()}
                        </div>
                        
                        <div class="form-footer">
                            <button type="submit" class="submit-btn" disabled>
                                <span class="btn-text">${this.escapeHtml(this.config.submitText)}</span>
                                <span class="btn-spinner" style="display: none;">
                                    <span class="spinner"></span>
                                </span>
                            </button>
                        </div>
                        
                        <div class="form-messages">
                            <div class="success-message" style="display: none;"></div>
                            <div class="error-message" style="display: none;"></div>
                        </div>
                    </form>
                </div>
            `;

            this.container.innerHTML = formHTML;
            this.form = document.getElementById(formId);
        }

        /**
         * Render form fields based on configuration
         */
        renderFields() {
            return this.config.fields.map(fieldName => {
                const field = VALIDATION_RULES[fieldName];
                if (!field) return '';

                // Check if field is required (from config or default rules)
                const isRequired = this.config.requiredFields.includes(fieldName) || field.required;
                const fieldId = 'field-' + fieldName + '-' + Math.random().toString(36).substr(2, 9);

                const fieldType = field.fieldType || this.getDefaultFieldType(fieldName);
                const label = this.getFieldLabel(fieldName);
                const placeholder = this.getFieldPlaceholder(fieldName);
                const requiredIndicator = (isRequired && this.config.showRequiredIndicator) ? ' *' : '';

                switch (fieldType) {
                    case 'textarea':
                        return `
                            <div class="form-group">
                                <label for="${fieldId}" class="form-label">
                                    ${label}${requiredIndicator}
                                </label>
                                <textarea 
                                    id="${fieldId}" 
                                    name="${fieldName}" 
                                    class="form-input form-textarea"
                                    rows="4"
                                    placeholder="${placeholder}"
                                    ${isRequired ? 'required' : ''}
                                    maxlength="${field.maxLength || ''}"
                                ></textarea>
                                <div class="field-error" style="display: none;"></div>
                            </div>
                        `;
                    
                    case 'select':
                        const options = field.options || [];
                        const optionHtml = options.map(option => 
                            `<option value="${this.escapeHtml(option)}">${this.escapeHtml(option)}</option>`
                        ).join('');
                        
                        return `
                            <div class="form-group">
                                <label for="${fieldId}" class="form-label">
                                    ${label}${requiredIndicator}
                                </label>
                                <select 
                                    id="${fieldId}" 
                                    name="${fieldName}" 
                                    class="form-input form-select"
                                    ${isRequired ? 'required' : ''}
                                >
                                    <option value="">${placeholder || 'Select an option'}</option>
                                    ${optionHtml}
                                </select>
                                <div class="field-error" style="display: none;"></div>
                            </div>
                        `;
                    
                    case 'hidden':
                        return `
                            <input 
                                type="hidden" 
                                id="${fieldId}" 
                                name="${fieldName}" 
                                value="${this.escapeHtml(placeholder)}"
                            />
                        `;
                    
                    case 'number':
                        return `
                            <div class="form-group">
                                <label for="${fieldId}" class="form-label">
                                    ${label}${requiredIndicator}
                                </label>
                                <input 
                                    type="number" 
                                    id="${fieldId}" 
                                    name="${fieldName}" 
                                    class="form-input"
                                    placeholder="${placeholder}"
                                    ${isRequired ? 'required' : ''}
                                    min="0"
                                />
                                <div class="field-error" style="display: none;"></div>
                            </div>
                        `;
                    
                    default: // text, email, tel, url
                        const inputType = this.getInputType(fieldName, fieldType);
                        
                        return `
                            <div class="form-group">
                                <label for="${fieldId}" class="form-label">
                                    ${label}${requiredIndicator}
                                </label>
                                <input 
                                    type="${inputType}" 
                                    id="${fieldId}" 
                                    name="${fieldName}" 
                                    class="form-input"
                                    placeholder="${placeholder}"
                                    ${isRequired ? 'required' : ''}
                                    maxlength="${field.maxLength || ''}"
                                />
                                <div class="field-error" style="display: none;"></div>
                            </div>
                        `;
                }
            }).join('');
        }

        /**
         * Get field label
         */
        getFieldLabel(fieldName) {
            // Check for custom label first
            if (this.config.fieldLabels[fieldName]) {
                return this.config.fieldLabels[fieldName];
            }

            const labels = {
                name: 'Full Name',
                email: 'Email Address',
                company: 'Company',
                phone: 'Phone Number',
                details: 'Details'
            };
            return labels[fieldName] || fieldName.charAt(0).toUpperCase() + fieldName.slice(1);
        }

        /**
         * Get field placeholder
         */
        getFieldPlaceholder(fieldName) {
            // Check for custom placeholder first
            if (this.config.fieldPlaceholders[fieldName]) {
                return this.config.fieldPlaceholders[fieldName];
            }

            const placeholders = {
                name: 'Enter your full name',
                lastname: 'Enter your last name',
                email: 'Enter your email address',
                company: 'Enter your company name',
                phone: 'Enter your phone number',
                details: 'Tell me a little about what you hope to gain',
                website: 'https://yourwebsite.com',
                jobtitle: 'Enter your job title',
                industry: 'Select your industry',
                budget: 'Enter your budget'
            };
            return placeholders[fieldName] || '';
        }

        /**
         * Get default field type based on field name
         */
        getDefaultFieldType(fieldName) {
            const typeMap = {
                details: 'textarea',
                industry: 'select',
                budget: 'number',
                leadsource: 'hidden'
            };
            return typeMap[fieldName] || 'text';
        }

        /**
         * Get input type for HTML input element
         */
        getInputType(fieldName, fieldType) {
            if (fieldType && fieldType !== 'text') {
                return fieldType;
            }

            const typeMap = {
                email: 'email',
                phone: 'tel',
                website: 'url'
            };
            return typeMap[fieldName] || 'text';
        }

        /**
         * Attach event listeners
         */
        attachEventListeners() {
            // Form submission
            this.form.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleSubmit();
            });

            // Real-time validation
            const inputs = this.form.querySelectorAll('.form-input');
            inputs.forEach(input => {
                input.addEventListener('blur', () => this.validateField(input));
                input.addEventListener('input', () => {
                    this.clearFieldError(input);
                    this.updateSubmitButton();
                });
            });

            // Initial submit button state
            this.updateSubmitButton();
        }

        /**
         * Validate individual field
         */
        validateField(input) {
            const fieldName = input.name;
            const value = input.value.trim();
            const rules = VALIDATION_RULES[fieldName];
            
            if (!rules) return true;

            // Check required
            if (rules.required && !value) {
                this.showFieldError(input, `${this.getFieldLabel(fieldName)} is required`);
                return false;
            }

            // Skip other validations if field is empty and not required
            if (!value && !rules.required) {
                this.clearFieldError(input);
                return true;
            }

            // Check minimum length
            if (rules.minLength && value.length < rules.minLength) {
                this.showFieldError(input, rules.message);
                return false;
            }

            // Check maximum length
            if (rules.maxLength && value.length > rules.maxLength) {
                this.showFieldError(input, rules.message);
                return false;
            }

            // Check pattern
            if (rules.pattern && !rules.pattern.test(value)) {
                this.showFieldError(input, rules.message);
                return false;
            }

            this.clearFieldError(input);
            return true;
        }

        /**
         * Validate entire form
         */
        validateForm() {
            const inputs = this.form.querySelectorAll('.form-input');
            let isValid = true;

            inputs.forEach(input => {
                if (!this.validateField(input)) {
                    isValid = false;
                }
            });

            return isValid;
        }

        /**
         * Show field error
         */
        showFieldError(input, message) {
            const errorDiv = input.parentNode.querySelector('.field-error');
            errorDiv.textContent = message;
            errorDiv.style.display = 'block';
            input.classList.add('error');
        }

        /**
         * Clear field error
         */
        clearFieldError(input) {
            const errorDiv = input.parentNode.querySelector('.field-error');
            errorDiv.style.display = 'none';
            input.classList.remove('error');
        }

        /**
         * Update submit button state
         */
        updateSubmitButton() {
            const submitBtn = this.form.querySelector('.submit-btn');
            const requiredInputs = this.form.querySelectorAll('.form-input[required]');
            
            let allRequiredFilled = true;
            requiredInputs.forEach(input => {
                if (!input.value.trim()) {
                    allRequiredFilled = false;
                }
            });

            submitBtn.disabled = !allRequiredFilled || this.isSubmitting;
        }

        /**
         * Handle form submission
         */
        async handleSubmit() {
            if (this.isSubmitting) return;

            // Validate form
            if (!this.validateForm()) {
                this.showMessage('Please fix the errors above', 'error');
                return;
            }

            this.isSubmitting = true;
            this.showSubmitSpinner(true);
            this.hideMessages();

            try {
                const formData = this.getFormData();
                const response = await this.submitToAPI(formData);

                if (response.success) {
                    this.showMessage(this.config.successMessage, 'success');
                    this.resetForm();
                } else {
                    throw new Error(response.error?.message || 'Submission failed');
                }
            } catch (error) {
                console.error('Form submission error:', error);
                this.showMessage(this.config.errorMessage, 'error');
            } finally {
                this.isSubmitting = false;
                this.showSubmitSpinner(false);
                this.updateSubmitButton();
            }
        }

        /**
         * Get form data with Mautic field mapping
         */
        getFormData() {
            const formData = new FormData(this.form);
            const data = {
                timestamp: new Date().toISOString(),
                source: window.location.hostname,
                referrer: document.referrer || '',
                userAgent: navigator.userAgent,
                pageUrl: window.location.href,
                contact: {},
                mauticFields: {} // Mautic-compatible field mapping
            };

            // Process form fields
            for (let [key, value] of formData.entries()) {
                if (value && value.toString().trim()) {
                    const trimmedValue = value.toString().trim();
                    data.contact[key] = trimmedValue;

                    // Map to Mautic field if defined
                    const fieldRule = VALIDATION_RULES[key];
                    if (fieldRule && fieldRule.mauticField) {
                        data.mauticFields[fieldRule.mauticField] = trimmedValue;
                    }
                }
            }

            // Add tracking data
            data.tracking = {
                formId: this.container.id || 'lead-capture-form',
                sessionId: this.getSessionId(),
                utmSource: this.getUrlParameter('utm_source'),
                utmMedium: this.getUrlParameter('utm_medium'),
                utmCampaign: this.getUrlParameter('utm_campaign'),
                utmTerm: this.getUrlParameter('utm_term'),
                utmContent: this.getUrlParameter('utm_content')
            };

            if (this.config.debugMode) {
                console.log('Form Data:', data);
            }

            return data;
        }

        /**
         * Get or create session ID for tracking
         */
        getSessionId() {
            let sessionId = sessionStorage.getItem('leadCaptureSessionId');
            if (!sessionId) {
                sessionId = 'session-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
                sessionStorage.setItem('leadCaptureSessionId', sessionId);
            }
            return sessionId;
        }

        /**
         * Get URL parameter value
         */
        getUrlParameter(name) {
            const urlParams = new URLSearchParams(window.location.search);
            return urlParams.get(name) || '';
        }

        /**
         * Submit data to API with CORS handling
         */
        async submitToAPI(data) {
            // Prepare headers
            const headers = {
                'Content-Type': 'application/json',
            };

            // Add API key if provided
            if (this.config.apiKey) {
                headers['X-API-Key'] = this.config.apiKey;
            }

            // Add origin for CORS validation
            headers['Origin'] = window.location.origin;

            // Validate domain if allowed domains are specified
            if (this.config.allowedDomains && this.config.allowedDomains.length > 0) {
                const currentDomain = window.location.hostname;
                const isAllowed = this.config.allowedDomains.some(domain => {
                    // Support wildcard subdomains
                    if (domain.startsWith('*.')) {
                        const baseDomain = domain.substring(2);
                        return currentDomain.endsWith(baseDomain);
                    }
                    return currentDomain === domain;
                });

                if (!isAllowed) {
                    throw new Error('Form submission not allowed from this domain');
                }
            }

            try {
                const response = await fetch(this.config.apiEndpoint, {
                    method: 'POST',
                    headers: headers,
                    body: JSON.stringify(data),
                    mode: 'cors', // Explicitly set CORS mode
                    credentials: 'omit' // Don't send cookies for security
                });

                // Handle different response types
                if (!response.ok) {
                    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
                    
                    // Try to get more detailed error from response
                    try {
                        const errorData = await response.json();
                        if (errorData.error && errorData.error.message) {
                            errorMessage = errorData.error.message;
                        } else if (errorData.message) {
                            errorMessage = errorData.message;
                        }
                    } catch (e) {
                        // Response is not JSON, use status text
                    }

                    throw new Error(errorMessage);
                }

                // Parse response
                const responseData = await response.json();
                
                if (this.config.debugMode) {
                    console.log('API Response:', responseData);
                }

                return responseData;

            } catch (error) {
                // Enhanced error handling for different types of failures
                if (error.name === 'TypeError' && error.message.includes('fetch')) {
                    // Network error or CORS issue
                    throw new Error('Unable to connect to the server. Please check your internet connection.');
                } else if (error.name === 'AbortError') {
                    // Request timeout
                    throw new Error('Request timed out. Please try again.');
                } else {
                    // Re-throw the original error
                    throw error;
                }
            }
        }

        /**
         * Show submit spinner
         */
        showSubmitSpinner(show) {
            const btnText = this.form.querySelector('.btn-text');
            const btnSpinner = this.form.querySelector('.btn-spinner');
            
            if (show) {
                btnText.style.display = 'none';
                btnSpinner.style.display = 'inline-block';
            } else {
                btnText.style.display = 'inline-block';
                btnSpinner.style.display = 'none';
            }
        }

        /**
         * Show message
         */
        showMessage(message, type) {
            this.hideMessages();
            const messageDiv = this.form.querySelector(`.${type}-message`);
            messageDiv.textContent = message;
            messageDiv.style.display = 'block';
        }

        /**
         * Hide all messages
         */
        hideMessages() {
            const messages = this.form.querySelectorAll('.success-message, .error-message');
            messages.forEach(msg => msg.style.display = 'none');
        }

        /**
         * Reset form
         */
        resetForm() {
            this.form.reset();
            this.clearAllErrors();
            this.updateSubmitButton();
        }

        /**
         * Clear all field errors
         */
        clearAllErrors() {
            const inputs = this.form.querySelectorAll('.form-input');
            inputs.forEach(input => this.clearFieldError(input));
        }

        /**
         * Escape HTML to prevent XSS
         */
        escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    }

    /**
     * Auto-initialize forms on page load
     */
    function initializeForms() {
        const containers = document.querySelectorAll('[id^="lead-capture-form"]');
        
        containers.forEach(container => {
            // Skip if already initialized
            if (container.querySelector('.lead-capture-wrapper')) return;

            // Get configuration from data attributes
            const config = {
                apiEndpoint: container.dataset.apiEndpoint || DEFAULT_CONFIG.apiEndpoint,
                fields: container.dataset.fields || DEFAULT_CONFIG.fields,
                title: container.dataset.title || DEFAULT_CONFIG.title,
                submitText: container.dataset.submitText || DEFAULT_CONFIG.submitText,
                successMessage: container.dataset.successMessage || DEFAULT_CONFIG.successMessage,
                errorMessage: container.dataset.errorMessage || DEFAULT_CONFIG.errorMessage,
                theme: container.dataset.theme || DEFAULT_CONFIG.theme,
                width: container.dataset.width || DEFAULT_CONFIG.width,
                position: container.dataset.position || DEFAULT_CONFIG.position,
                // Advanced configuration
                requiredFields: container.dataset.requiredFields || DEFAULT_CONFIG.requiredFields,
                fieldLabels: container.dataset.fieldLabels || DEFAULT_CONFIG.fieldLabels,
                fieldPlaceholders: container.dataset.fieldPlaceholders || DEFAULT_CONFIG.fieldPlaceholders,
                validationMessages: container.dataset.validationMessages || DEFAULT_CONFIG.validationMessages,
                submitOnEnter: container.dataset.submitOnEnter !== 'false', // Default true
                showRequiredIndicator: container.dataset.showRequiredIndicator !== 'false', // Default true
                autoFocus: container.dataset.autoFocus === 'true', // Default false
                resetOnSuccess: container.dataset.resetOnSuccess !== 'false', // Default true
                allowedDomains: container.dataset.allowedDomains || DEFAULT_CONFIG.allowedDomains,
                apiKey: container.dataset.apiKey || DEFAULT_CONFIG.apiKey,
                customCss: container.dataset.customCss || DEFAULT_CONFIG.customCss,
                debugMode: container.dataset.debugMode === 'true' // Default false
            };

            // Initialize form
            new LeadCaptureForm(container, config);
        });
    }

    /**
     * Public API
     */
    window.LeadCaptureForm = LeadCaptureForm;

    /**
     * Auto-initialize when DOM is ready
     */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeForms);
    } else {
        initializeForms();
    }

})();