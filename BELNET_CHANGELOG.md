# Changelog Belnet version
> **Note:**  
> From v5.0.0 Belnet will follow its own versioning, but mention the used roadmap version
 
## Release Notes v5.0.0 Draft
### Based on DMPRoadmap version v5.0.2
### Functional changes
- Added Mailhog service to capture outgoing emails. Handy when testing in a "sandbox" environment
 
### Resolved issues
- Admin panel is now accessible. Caused by timestamptz (Time Stamp Time Zone) not correctly being able to be read
 
### Other changes without functional impact
- Upgrade to latest community version (from 4.2.0 to 5.0.2)
- Moved code from large module_overrides.rb file to their own classes
- Updated docker-compose.yml
 
### Known limitations
- None