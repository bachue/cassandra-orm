require 'active_support/proxy_object'

class AsyncWrapper < ActiveSupport::ProxyObject
  def initialize object, sync_method, &block
    @object, @sync_method, @handler = object, sync_method, block
  end

  def method_missing method, *args, &block
    if @object.respond_to? method
      @object.__send__ method, *args, &block
    else
      __getobj__.__send__ method, *args, &block
    end
  end

  def __getobj__
    @result ||= begin
      result = @object.__send__ @sync_method
      result = @handler.call result if @handler
      result
    end
  end

end
