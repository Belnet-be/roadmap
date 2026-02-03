# Changelog Belnet version
> **Note:** From v5.0.0 Belnet will follow its own versioning, but mention the used roadmap version

<div class="card mb-4" markdown="1">

<div class="card-header" markdown="1">
## Release Notes v5.0.0 Draft
</div>
<div class="card-body" markdown="1">

### Based on DMPRoadmap version v5.0.2

### Functional changes
- Added Mailhog service to capture outgoing emails. Handy when testing in a "sandbox" environment
- /version page that shows technical information about DMPonline & versions of dependencies
- /api_documentation page with tabs that outlines the usecases for the API's that are available in DMPonline
- /belnet_changelog page with changes from Belnet to DMPonline

### Resolved issues
- Admin panel is now accessible. Caused by timestamptz (Time Stamp Time Zone) not correctly being able to be read

### Other changes without functional impact
- Upgrade to latest community version (from 4.2.0 to 5.0.2)
- Moved code from large module_overrides.rb file to their own classes
- Updated docker-compose.yml
- Added script (task) for creating and removing test users from the database in 5 roles

### Known limitations
- None

</div>
</div>