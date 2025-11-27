# Belnet tasks to support development and test environments
# Usage: rails belnet_dev:setup_test_users
# Usage: rails belnet_dev:destroy_test_users

namespace :belnet_dev do
  desc "Setup or destroy test users"
  task setup_test_users: :environment do
    puts "Setting up test users in the environment..."

    # Find organisations

    kul_org = Org.where(managed: true, abbreviation: 'KUL').first
    liege_org = Org.where(managed: true, abbreviation: 'ULiege').first

    # Create org domains for each user
    # There are two types of researchers, KUL and ULiege
    # The rest of the users get a standardized org domain (@testuser.be), this is an org domain in the Liege org

    researcher_kul_org_domain = Ugent::OrgDomain.new(name: 'testuser-kul.be', org_id: kul_org.id)
    researcher_liege_org_domain = Ugent::OrgDomain.new(name: 'testuser-liege.be', org_id: liege_org.id)
    testuser_liege_org_domain = Ugent::OrgDomain.new(name: 'testuser.be', org_id: liege_org.id)

    researcher_kul_org_domain.save!
    researcher_liege_org_domain.save!
    testuser_liege_org_domain.save!

    # Create default users

    researcher_kul = User.new(email: 'researcher.kul@testuser-kul.be', firstname: 'Jane', surname: 'Doe')
    researcher_kul.password = researcher_kul.email
    researcher_kul.password_confirmation = researcher_kul.email
    researcher_kul.save!

    researcher_liege = User.new(email: 'researcher.liege@testuser-liege.be', firstname: 'John', surname: 'Smith')
    researcher_liege.password = researcher_liege.email
    researcher_liege.password_confirmation = researcher_liege.email
    researcher_liege.save!

    data_steward_liege = User.new(email: 'datasteward@testuser.be', firstname: 'Alice', surname: 'Johnson')
    data_steward_liege.perms = [Perm.grant_permissions, Perm.modify_templates, Perm.modify_guidance,
                                Perm.change_org_details, Perm.review_plans]
    data_steward_liege.password = data_steward_liege.email
    data_steward_liege.password_confirmation = data_steward_liege.email
    data_steward_liege.save!

    organisational_admin_liege = User.new(email: 'orgadmin@testuser.be', firstname: 'Bob', surname: 'Brown')
    organisational_admin_liege.perms = [Perm.grant_permissions, Perm.modify_templates, Perm.modify_guidance, Perm.use_api,
                                        Perm.change_org_details, Perm.review_plans]
    organisational_admin_liege.password = organisational_admin_liege.email
    organisational_admin_liege.password_confirmation = organisational_admin_liege.email
    organisational_admin_liege.save!

    super_admin_liege = User.new(email: 'superadmin@testuser.be', firstname: 'Charlie', surname: 'Davis')
    super_admin_liege.perms = Perm.all
    super_admin_liege.password = super_admin_liege.email
    super_admin_liege.password_confirmation = super_admin_liege.email
    super_admin_liege.save!

    puts "Setting up test users completed."
  end
  task destroy_test_users: :environment do
    puts "Destroying test users in the environment..."

    researcher_kul.destroy!
    researcher_liege.destroy!
    data_steward_liege.destroy!
    organisational_admin_liege.destroy!
    super_admin_liege.destroy!
 
    researcher_kul_org_domain.destroy!
    researcher_liege_org_domain.destroy!
    testuser_liege_org_domain.destroy!

    puts "Destroying test users completed."
  end
end