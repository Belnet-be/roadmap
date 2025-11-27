module RolesControllerExtension
  extend ActiveSupport::Concern

  after_action(only: %i[create]) do |controller|
    # only apply when role was persisted, and therefore valid
    next unless @role.persisted?

    # no boxes checked, no parameters sent
    controller.params[:contributor] ||= Hash[Contributor.roles.map { |cr| [cr, 0] }]

    contributor_params = controller.params
                                   .require(:contributor)
                                   .permit(*Contributor.roles)

    contributor = Contributor.where(plan_id: @role.plan_id, email: @role.user.email)
                             .first

    contributor = Contributor.new(plan_id: @role.plan_id, email: @role.user.email) if contributor.nil?

    contributor.roles = 0

    Contributor.roles.each do |contributor_access|
      if contributor_params.key?(contributor_access.to_s)
        contributor.send("#{contributor_access}=", contributor_params[contributor_access])
      end
    end

    if contributor.roles == 0

      contributor.destroy if contributor.persisted?

    else

      contributor.update_from_user(@role.user)
      contributor.save!

    end
  end
end
