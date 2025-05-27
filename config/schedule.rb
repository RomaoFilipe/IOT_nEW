every 1.minute do
  runner "IrrigationSchedulerJob.perform_later"
end
