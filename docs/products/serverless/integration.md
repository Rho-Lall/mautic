# Lead Capture Form Integration Guide

This guide shows you exactly how to add the lead capture form to your static website. Follow these simple steps to get your form working in minutes.

## 📋 Quick Integration Checklist

1. ✅ Copy the form files to your website
2. ✅ Add the HTML snippet where you want the form
3. ✅ Include the CSS and JavaScript files
4. ✅ Configure your API endpoint
5. ✅ Test the form

## 🚀 Step-by-Step Integration

### Step 1: Copy Form Files

**Copy these files to your website:**

```
your-website/
├── assets/
│   ├── lead-capture.js     ← Copy this file
│   └── lead-capture.css    ← Copy this file
└── index.html              ← Your existing page
```

**Files to copy:**
- `src/client/lead-capture.js` → `assets/lead-capture.js`
- `src/client/lead-capture.css` → `assets/lead-capture.css`

### Step 2: Add HTML Snippet

**Copy and paste this HTML where you want the form to appear:**

```html
<!-- Lead Capture Form -->
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api-endpoint.com/leads"
     data-fields="name,email,details"
     data-title="Get in Touch"
     data-submit-text="Send Message">
</div>
```

**⚠️ Important:** Replace `https://your-api-endpoint.com/leads` with your actual API endpoint URL.

### Step 3: Include CSS and JavaScript

**Add these lines to your HTML page:**

**In the `<head>` section:**
```html
<link rel="stylesheet" href="assets/lead-capture.css">
```

**Before the closing `</body>` tag:**
```html
<script src="assets/lead-capture.js"></script>
```

### Step 4: Complete HTML Example

Here's a complete HTML page with the form integrated:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Website</title>
    
    <!-- Include form CSS -->
    <link rel="stylesheet" href="assets/lead-capture.css">
</head>
<body>
    <h1>Welcome to My Website</h1>
    <p>Your existing content goes here...</p>
    
    <!-- Lead Capture Form -->
    <div id="lead-capture-form" 
         data-api-endpoint="https://your-api-endpoint.com/leads"
         data-fields="name,email,details"
         data-title="Contact Us"
         data-submit-text="Get Started">
    </div>
    
    <!-- Include form JavaScript -->
    <script src="assets/lead-capture.js"></script>
</body>
</html>
```

## 🎨 Customization Options

### Basic Configuration

Change these `data-` attributes to customize your form:

```html
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api.com/leads"
     data-fields="name,email,company,phone,details"
     data-title="Request a Quote"
     data-submit-text="Get My Quote"
     data-success-message="Thanks! We'll send your quote within 24 hours."
     data-theme="dark"
     data-width="compact">
</div>
```

### Available Fields

Choose from these fields for `data-fields`:
- `name` - Full name (required)
- `email` - Email address (always required)
- `company` - Company name
- `phone` - Phone number
- `details` - Additional details/message
- `website` - Website URL
- `jobtitle` - Job title

### Theme Options

- `data-theme="light"` - Light theme (default)
- `data-theme="dark"` - Dark theme

### Width Options

- `data-width="full"` - Full width (default)
- `data-width="compact"` - Compact width (400px max)

## 🌐 Platform-Specific Integration

### GitHub Pages

**1. Add files to your repository:**
```
your-repo/
├── assets/
│   ├── lead-capture.js
│   └── lead-capture.css
└── index.md (or index.html)
```

**2. In your Markdown file:**
```markdown
---
layout: default
---

# My Page Title

Your content here...

<div id="lead-capture-form" 
     data-api-endpoint="https://your-api.com/leads"
     data-fields="name,email,details">
</div>

<link rel="stylesheet" href="assets/lead-capture.css">
<script src="assets/lead-capture.js"></script>
```

### Jekyll

**1. Add files to `assets/` folder**

**2. Create `_includes/lead-capture-form.html`:**
```html
<div id="lead-capture-form-{{ include.id | default: 'default' }}" 
     data-api-endpoint="{{ include.api_endpoint }}"
     data-fields="{{ include.fields | default: 'name,email,details' }}"
     data-title="{{ include.title | default: 'Contact Us' }}"
     data-submit-text="{{ include.submit_text | default: 'Submit' }}">
</div>
```

**3. In your layout file (`_layouts/default.html`):**
```html
<head>
    <!-- Other head content -->
    <link rel="stylesheet" href="{{ '/assets/lead-capture.css' | relative_url }}">
</head>
<body>
    <!-- Body content -->
    <script src="{{ '/assets/lead-capture.js' | relative_url }}"></script>
</body>
```

**4. Use in any page:**
```markdown
---
layout: default
---

# Contact Page

{% raw %}{% include lead-capture-form.html 
   api_endpoint="https://your-api.com/leads"
   fields="name,email,company,details"
   title="Get in Touch" %}{% endraw %}
```

### Gatsby (React)

**1. Add files to `static/` folder:**
```
static/
├── lead-capture.js
└── lead-capture.css
```

**2. In your component:**
```jsx
import React, { useEffect } from 'react';
import { Helmet } from 'react-helmet';

const ContactPage = () => {
  useEffect(() => {
    // Load the form script after component mounts
    const script = document.createElement('script');
    script.src = '/lead-capture.js';
    script.async = true;
    document.body.appendChild(script);

    return () => {
      // Cleanup
      document.body.removeChild(script);
    };
  }, []);

  return (
    <>
      <Helmet>
        <link rel="stylesheet" href="/lead-capture.css" />
      </Helmet>
      
      <h1>Contact Us</h1>
      
      <div id="lead-capture-form" 
           data-api-endpoint="https://your-api.com/leads"
           data-fields="name,email,company,details"
           data-title="Get in Touch">
      </div>
    </>
  );
};

export default ContactPage;
```

### Next.js

**1. Add files to `public/` folder:**
```
public/
├── lead-capture.js
└── lead-capture.css
```

**2. Create a component:**
```jsx
import { useEffect } from 'react';
import Head from 'next/head';

export default function ContactForm({ apiEndpoint, fields = "name,email,details" }) {
  useEffect(() => {
    // Load script dynamically
    const script = document.createElement('script');
    script.src = '/lead-capture.js';
    script.async = true;
    document.body.appendChild(script);

    return () => {
      if (document.body.contains(script)) {
        document.body.removeChild(script);
      }
    };
  }, []);

  return (
    <>
      <Head>
        <link rel="stylesheet" href="/lead-capture.css" />
      </Head>
      
      <div id="lead-capture-form" 
           data-api-endpoint={apiEndpoint}
           data-fields={fields}
           data-title="Contact Us">
      </div>
    </>
  );
}
```

**3. Use in a page:**
```jsx
import ContactForm from '../components/ContactForm';

export default function Contact() {
  return (
    <div>
      <h1>Contact Us</h1>
      <ContactForm 
        apiEndpoint="https://your-api.com/leads"
        fields="name,email,company,details" 
      />
    </div>
  );
}
```

### Hugo

**1. Add files to `static/` folder:**
```
static/
├── js/
│   └── lead-capture.js
└── css/
    └── lead-capture.css
```

**2. In your layout (`layouts/_default/baseof.html`):**
```html
<head>
    <!-- Other head content -->
    <link rel="stylesheet" href="{{ "css/lead-capture.css" | relURL }}">
</head>
<body>
    <!-- Body content -->
    <script src="{{ "js/lead-capture.js" | relURL }}"></script>
</body>
```

**3. Create a shortcode (`layouts/shortcodes/lead-capture.html`):**
```html
<div id="lead-capture-form-{{ .Get "id" | default "default" }}" 
     data-api-endpoint="{{ .Get "api" }}"
     data-fields="{{ .Get "fields" | default "name,email,details" }}"
     data-title="{{ .Get "title" | default "Contact Us" }}">
</div>
```

**4. Use in content:**
```markdown
---
title: "Contact"
---

# Get in Touch

{{< lead-capture api="https://your-api.com/leads" fields="name,email,company" title="Contact Sales" >}}
```

## 🔧 Advanced Configuration

### Custom Field Labels and Placeholders

```html
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api.com/leads"
     data-fields="name,email,company,details"
     data-field-labels='{"name":"Full Name","details":"Project Requirements"}'
     data-field-placeholders='{"name":"Enter your full name","details":"Tell us about your project"}'>
</div>
```

### Domain Restrictions (Security)

```html
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api.com/leads"
     data-fields="name,email,details"
     data-allowed-domains="yourdomain.com,*.yourdomain.com">
</div>
```

### API Authentication

```html
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api.com/leads"
     data-fields="name,email,details"
     data-api-key="your-api-key-here">
</div>
```

## ✅ Testing Your Integration

### 1. Visual Check
- Form appears on your page
- Styling looks correct
- All fields are present

### 2. Functionality Test
- Try submitting with empty required fields (should show errors)
- Try invalid email (should show error)
- Try valid submission (should show success message)

### 3. Network Test
Open browser developer tools (F12) and check:
- No JavaScript errors in Console
- Form submission appears in Network tab
- API endpoint receives the data

### 4. Mobile Test
- Form works on mobile devices
- Form is responsive and readable
- Touch interactions work properly

## 🚨 Common Issues and Solutions

### Form Doesn't Appear
**Problem:** The form div is empty
**Solution:** 
- Check that JavaScript file is loaded correctly
- Verify the file path in your script tag
- Check browser console for errors

### Styling Issues
**Problem:** Form looks broken or unstyled
**Solution:**
- Verify CSS file is loaded correctly
- Check the file path in your link tag
- Ensure no CSS conflicts with your site

### Submission Fails
**Problem:** Form shows error message on submit
**Solution:**
- Verify your API endpoint URL is correct
- Check CORS settings on your API
- Verify API is accepting POST requests

### CORS Errors
**Problem:** Browser blocks the request
**Solution:**
- Configure your API to allow requests from your domain
- Add proper CORS headers to your API response
- Use `data-allowed-domains` if needed

## 📞 Need Help?

If you're still having issues:

1. **Check the browser console** (F12) for error messages
2. **Verify file paths** are correct for your site structure
3. **Test with the example HTML** file first
4. **Check your API endpoint** with a tool like Postman

---

**Ready to integrate?** Start with the basic HTML example above and customize from there!