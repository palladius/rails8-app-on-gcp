# Email Delivery Architecture & Cloud Run Sendmail Teachable Moment

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Provide an end-to-end ActionMailer email notification workflow in the Rails app, documenting why raw `sendmail` (port 25) is blocked/blackholed on Google Cloud Run, and implementing a robust dual-mode email system (Local Mailpit interceptor vs Cloud SMTP/API relay).

**Architecture:** 
- In development/Docker Compose, ActionMailer routes through **Mailpit** (SMTP port 1025 / Web UI 8025) for zero-spam local testing.
- In production/Cloud Run, ActionMailer demonstrates why `sendmail` (port 25) fails due to GCP egress filtering, and configures TLS relay on port 587 (or HTTP email API) via Secret Manager credentials.
- Adds an `AdminMailer` / `WelcomeMailer` flow triggered when a user registers or publishes a post.

**Tech Stack:** Rails 8 ActionMailer, Mailpit, Google Cloud Run, Google Cloud Secret Manager.

---

## 🔍 Deep-Dive: Does Cloud Run Support `sendmail`?

### 🚫 The Reality of Port 25 on Google Cloud
- **Standard Port 25 is Blocked:** Google Cloud unconditionally blocks outbound connections to destination port `25` on Compute Engine, GKE, and Cloud Run to mitigate spam abuse.
- **`sendmail` Binary in Containers:** While you *can* install `/usr/sbin/sendmail` inside a Debian container, when `sendmail` attempts to resolve the recipient MX record and connect to remote mail servers over port 25, GCP packet filters drop the traffic silently (**blackholed**).
- **Deliverability & Reputation:** Even if port 25 were open, ephemeral Cloud Run IP addresses lack reverse DNS (PTR records), SPF, DKIM, and DMARC alignment, meaning destination servers (Gmail, Outlook) would immediately flag emails as spam.

### 🛡️ What Actually Works on Cloud Run
1. **Secure SMTP Relay over Port 587 (STARTTLS) or 465 (SSL):** Egress on ports `587` and `465` is fully open on Cloud Run. Services like SendGrid, Mailgun, Postmark, AWS SES, or Google Workspace SMTP Relay (`smtp.gmail.com:587`) work seamlessly.
2. **REST API Egress (HTTPS / Port 443):** Modern transactional services (Resend, SendGrid API, Postmark API) send emails over HTTP POST requests, bypassing SMTP entirely.
3. **Local Dev & Workshop Interceptor (Mailpit):** Developers test email generation in browser without real credentials.

---

## 📋 Task Breakdown

### Task 1: Add ActionMailer Welcome/Notification Mailer

**Files:**
- Create: `blog/app/mailers/user_mailer.rb`
- Create: `blog/app/views/user_mailer/welcome_email.html.erb`
- Create: `blog/app/views/user_mailer/welcome_email.text.erb`
- Create: `blog/test/mailers/user_mailer_test.rb`

**Step 1: Write the failing test**
```ruby
# blog/test/mailers/user_mailer_test.rb
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "welcome_email creates email with correct recipient and subject" do
    user = users(:one)
    email = UserMailer.with(user: user).welcome_email

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email_address], email.to
    assert_equal ["no-reply@rails8-gcp.example.com"], email.from
    assert_includes email.subject, "Welcome to Rails 8 on GCP"
    assert_includes email.body.encoded, "Welcome"
  end
end
```

**Step 2: Run test to verify it fails**
Run: `cd blog && bundle exec rails test test/mailers/user_mailer_test.rb`
Expected: FAIL with `NameError: uninitialized constant UserMailer`

**Step 3: Implement minimal UserMailer**
```ruby
# blog/app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  default from: "no-reply@rails8-gcp.example.com"

  def welcome_email
    @user = params[:user]
    mail(to: @user.email_address, subject: "🎉 Welcome to Rails 8 on GCP!")
  end
end
```

Create view templates:
```html
<!-- blog/app/views/user_mailer/welcome_email.html.erb -->
<h1>Welcome, <%= @user.email_address %>! 🦖</h1>
<p>Your Rails 8 on Google Cloud account is ready.</p>
<p>Visit your dashboard to start creating articles with AI-powered covers!</p>
```

```text
<!-- blog/app/views/user_mailer/welcome_email.text.erb -->
Welcome, <%= @user.email_address %>!
Your Rails 8 on Google Cloud account is ready.
```

**Step 4: Run test to verify it passes**
Run: `cd blog && bundle exec rails test test/mailers/user_mailer_test.rb`
Expected: PASS

**Step 5: Commit**
```bash
git add blog/app/mailers/ blog/app/views/user_mailer/ blog/test/mailers/
git commit -m "feat(mailer): add UserMailer welcome_email flow"
```

---

### Task 2: Configure ActionMailer Production & Development Settings

**Files:**
- Modify: `blog/config/environments/development.rb`
- Modify: `blog/config/environments/production.rb`

**Step 1: Configure Production ActionMailer for Secure Cloud Relay**
```ruby
# In blog/config/environments/production.rb:
# Configure email delivery for Cloud Run:
# NOTE: Raw sendmail / port 25 is blackholed by GCP egress filters.
# Use authenticated SMTP (port 587) or REST API.
if ENV["SMTP_ADDRESS"].present?
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              ENV["SMTP_ADDRESS"],
    port:                 ENV.fetch("SMTP_PORT", 587).to_i,
    user_name:            ENV["SMTP_USERNAME"],
    password:             ENV["SMTP_PASSWORD"],
    authentication:       :plain,
    enable_starttls_auto: true
  }
else
  # Safe fallback for workshop without active SMTP credentials:
  # Logs deliveries to Cloud Logging instead of crashing
  config.action_mailer.delivery_method = :log
end
```

**Step 2: Verify `just test` passes**
Run: `just test`
Expected: PASS

**Step 3: Commit**
```bash
git add blog/config/environments/
git commit -m "config(mailer): configure secure SMTP relay and safe logging fallback for Cloud Run"
```

---

### Task 3: Update Workshop Codelab & Constitution with Email Teachable Moments

**Files:**
- Modify: `workshop/UNTOUCHABLE-CONSTITUTION.md`
- Modify: `workshop/CODELAB.md`

**Step 1: Document the "Sendmail on Cloud Run" Security Teachable Moment**
Add callout explaining:
1. Why `sendmail` fails on GCP (Port 25 egress block).
2. How Mailpit intercepts locally on port 1025.
3. How to configure port 587 / Secret Manager for production emails.

**Step 2: Rebuild static pages**
Run: `just build-ghpages`

**Step 3: Commit & Push**
```bash
git add workshop/
git commit -m "docs: add sendmail on Cloud Run security analysis to workshop"
just autopush
```
