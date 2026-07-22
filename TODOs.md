This we need to fix

1. [ricc] Terraform state shoul be on GCS and setup on GCS properly, taking from .env. If we migrate .env, no biggie, we have a different state :) 
2. [ricc] There's should be a script like "just project-status" which says things like:
  1. - app GCS exists, contains N pics
  2. - DB exists, contains N posts /..
  3. - TF GCS exists, ...
  4. Lets use an aggressive default over configuration naming GCS buckets as {PROJECT_ID}-{SOMETHING_ELSE} so project auto determines the 2 above GCS buckets and low probability of collision (eg 2 tfstates for 2 projects).
3. [ricc] CHANGEMANAGEMENT: Lets avoid collisions. If I change a project id, i shouldnt overwrite a resources (eg a private key or a bucket folder, ...). Let's ensure all naming and folders on GCS and Secrets... have some sort of project_id embedded iin the name if we're at risk of collision. Let's not over do it! If Secret Manager has a rthing called "mypass" it shouldnt become "PROJECT_ID-mypass" unless there's a possibility that another project id writes this same secret in this very Project id, which seems unlikely.