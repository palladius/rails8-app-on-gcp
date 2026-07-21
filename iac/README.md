We want to be able to have an app fuily automated on GCP:
1. DB on Cloud SQL / AlloyDB - TBD
2. App on Cloud run, via docker-compose (yes, Cloud run now supports docker-compose)
3. Images and blobs on GCS. Use ActiveStorage with private access to images and media.
4. Top feature: An upload to rich-text post with images and stuff will result in a seamless upload to GCS and a sticky image (different per RAILS_ENV namespace of course!)

This is hard to do.
Luckily we have a sample app in `rails8-turbo-chat-2026` which you can find in ~/git/rails8-turbo-chat-2026/ and you can use as a source of inspiration.