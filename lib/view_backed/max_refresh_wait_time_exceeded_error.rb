module ViewBacked
  class MaxRefreshWaitTimeExceededError < StandardError
    def message
      'Max refresh wait time exceeded'
    end
  end
end
