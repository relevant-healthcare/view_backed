module ViewBacked
  class MaxWaitUntilPopulatedTimeExceededError < StandardError
    def message
      'Max time to wait until view is populated has been exceeded'
    end
  end
end
