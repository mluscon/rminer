

class Variable
  attr_accessor :name, :priority, :regexp

  def initialize(priority, name, regexp)
    @priority=priority
    @name=name
    @regexp=regexp
  end
end
