Rails.configuration.to_prepare do
  PlanExportsController.class_eval do
    prepend PlanExportsControllerExtension
  end
end
