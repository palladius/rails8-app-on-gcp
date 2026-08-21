# Setup and Prerequisites

> 💡 **Imagine:** Your boss wants you to take an old application and revive it; the last developer left the company, the language went End of Life 5 years ago, but still the application has strong business value for you. You heard the application has clear-text passwords in the code (dev was in a hurry to change role and didn't anticipate the success of this super app), and was deployed manually to production. Nobody remembers how it was done.

Before we begin, you will need a few things set up:

1. **A Google Cloud Project:** Ensure you have a GCP project created and billing enabled.
2. **Google Cloud CLI:** The `gcloud` CLI should be installed and authenticated (`gcloud auth login`).
3. **Ruby and Rails:** You should have Ruby 3.3+ and Rails 8 installed locally.
4. **Terraform:** We will use Terraform to provision the heavy infrastructure.

First, clone the workshop repository and move into the `workshop_1_local_baseline` branch:

```bash
git clone https://github.com/palladius/rails8-app-on-gcp.git
cd rails8-app-on-gcp
git checkout workshop_1_local_baseline
```

