# Belnet tasks to support development and test environments
# If usage is within docker terminal (bash) use:
# Usage: bin/rails belnet_dev:setup_test_users
# Usage: bin/rails belnet_dev:destroy_test_users
#
# If not using docker, use:
# Usage: rails belnet_dev:setup_test_users
# Usage: rails belnet_dev:destroy_test_users

namespace :belnet_dev do
  desc 'Setup or destroy test users'
  if %w[DEV TEST INT].include?(ENV['DMP_ENVIRONMENT'])
    task setup_test_users: :environment do
      puts 'Setting up test users in the environment...'

      # Find organisations

      kul_org = Org.where(managed: true, abbreviation: 'KUL').first
      liege_org = Org.where(managed: true, abbreviation: 'ULiege').first

      unless kul_org || liege_org
        puts 'KUL or ULiege organisation not found. Please ensure these organisations exist before running this task.'
        exit
      end

      # Create org domains for each user
      # There are two types of researchers, KUL and ULiege
      # The rest of the users get a standardized org domain (@testuser.be), this is an org domain in the Liege org
      unless Ugent::OrgDomain.exists?(name: 'testuser-kul.be')
        puts 'Creating org domain testuser-kul.be'
        researcher_kul_org_domain = Ugent::OrgDomain.new(name: 'testuser-kul.be', org_id: kul_org.id)
        researcher_kul_org_domain.save!
        puts 'Created org domain testuser-kul.be'
      end

      unless Ugent::OrgDomain.exists?(name: 'testuser-liege.be')
        puts 'Creating org domain testuser-liege.be'
        researcher_liege_org_domain = Ugent::OrgDomain.new(name: 'testuser-liege.be', org_id: liege_org.id)
        researcher_liege_org_domain.save!
        puts 'Created org domain testuser-liege.be'
      end

      unless Ugent::OrgDomain.exists?(name: 'testuser.be')
        puts 'Creating org domain testuser.be'
        testuser_liege_org_domain = Ugent::OrgDomain.new(name: 'testuser.be', org_id: liege_org.id)
        testuser_liege_org_domain.save!
        puts 'Created org domain testuser.be'
      end

      # Create default users

      unless User.exists?(email: 'researcher.kul@testuser-kul.be')
        puts 'Creating Researcher KUL'
        researcher_kul = User.new(email: 'researcher.kul@testuser-kul.be', firstname: 'Jane', surname: 'Doe')
        researcher_kul.password = researcher_kul.email
        researcher_kul.password_confirmation = researcher_kul.email
        researcher_kul.save!
        puts 'Created Researcher KUL'
      end

      unless User.exists?(email: 'researcher.liege@testuser-liege.be')
        puts 'Creating Researcher Liege'
        researcher_liege = User.new(email: 'researcher.liege@testuser-liege.be', firstname: 'John', surname: 'Smith')
        researcher_liege.password = researcher_liege.email
        researcher_liege.password_confirmation = researcher_liege.email
        researcher_liege.save!
        puts 'Created Researcher Liege'
      end

      unless User.exists?(email: 'datasteward@testuser.be')
        puts 'Creating Data Steward Liege'
        data_steward_liege = User.new(email: 'datasteward@testuser.be', firstname: 'Alice', surname: 'Johnson')
        data_steward_liege.perms = [Perm.grant_permissions, Perm.modify_templates, Perm.modify_guidance,
                                    Perm.change_org_details, Perm.review_plans]
        data_steward_liege.password = data_steward_liege.email
        data_steward_liege.password_confirmation = data_steward_liege.email
        data_steward_liege.save!
        puts 'Created Data Steward Liege'
      end

      unless User.exists?(email: 'orgadmin@testuser.be')
        puts 'Creating Organisational Admin Liege'
        organisational_admin_liege = User.new(email: 'orgadmin@testuser.be', firstname: 'Bob', surname: 'Brown')
        organisational_admin_liege.perms = [Perm.grant_permissions, Perm.modify_templates, Perm.modify_guidance, Perm.use_api,
                                            Perm.change_org_details, Perm.review_plans]
        organisational_admin_liege.password = organisational_admin_liege.email
        organisational_admin_liege.password_confirmation = organisational_admin_liege.email
        organisational_admin_liege.save!
        puts 'Created Organisational Admin Liege'
      end

      unless User.exists?(email: 'superadmin@testuser.be')
        puts 'Creating Super Admin Liege'
        super_admin_liege = User.new(email: 'superadmin@testuser.be', firstname: 'Charlie', surname: 'Davis')
        super_admin_liege.perms = Perm.all
        super_admin_liege.password = super_admin_liege.email
        super_admin_liege.password_confirmation = super_admin_liege.email
        super_admin_liege.save!
        puts 'Created Super Admin Liege'
      end

      puts 'Setting up test users & org domains completed.'
    end
    task destroy_test_users: :environment do
      puts 'Destroying test users in the environment...'

      # Find dummy users via email

      researcher_kul = User.find_by(email: 'researcher.kul@testuser-kul.be')
      researcher_liege = User.find_by(email: 'researcher.liege@testuser-liege.be')
      data_steward_liege = User.find_by(email: 'datasteward@testuser.be')
      organisational_admin_liege = User.find_by(email: 'orgadmin@testuser.be')
      super_admin_liege = User.find_by(email: 'superadmin@testuser.be')

      # Destroy dummy users

      if researcher_kul
        researcher_kul.destroy!
        puts 'Destroyed researcher_kul'
      end

      if researcher_liege
        researcher_liege.destroy!
        puts 'Destroyed researcher_liege'
      end

      if data_steward_liege
        data_steward_liege.destroy!
        puts 'Destroyed data_steward_liege'
      end

      if organisational_admin_liege
        organisational_admin_liege.destroy!
        puts 'Destroyed organisational_admin_liege'
      end

      if super_admin_liege
        super_admin_liege.destroy!
        puts 'Destroyed super_admin_liege'
      end

      # Remove org domains via name

      researcher_kul_org_domain = Ugent::OrgDomain.find_by(name: 'testuser-kul.be')
      researcher_liege_org_domain = Ugent::OrgDomain.find_by(name: 'testuser-liege.be')
      testuser_liege_org_domain = Ugent::OrgDomain.find_by(name: 'testuser.be')

      # Destroy org domains

      if researcher_kul_org_domain
        researcher_kul_org_domain.destroy!
        puts 'Destroyed researcher_kul_org_domain'
      end

      if researcher_liege_org_domain
        researcher_liege_org_domain.destroy!
        puts 'Destroyed researcher_liege_org_domain'
      end

      if testuser_liege_org_domain
        testuser_liege_org_domain.destroy!
        puts 'Destroyed testuser_liege_org_domain'
      end

      puts 'Destroying test users completed.'
    end
  else
    puts 'Belnet dev tasks are not available in this environment.'
  end
end
