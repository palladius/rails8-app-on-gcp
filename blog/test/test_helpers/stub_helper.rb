# Minimal singleton-method stubbing (minitest 6 ships without minitest/mock).
#
#   stub_singleton(Nanobanana, :credentials, nil) { ... }
#   stub_singleton(Nanobanana, :post_generate_content, ->(uri, body, token) { ... }) { ... }
#
# A callable replacement is invoked with the original arguments; anything else
# is returned as-is. The original method is restored after the block.
module StubHelper
  def stub_singleton(object, name, replacement)
    original = object.method(name)
    object.define_singleton_method(name) do |*args, **kwargs, &block|
      replacement.respond_to?(:call) ? replacement.call(*args, **kwargs, &block) : replacement
    end
    yield
  ensure
    object.singleton_class.send(:remove_method, name)
    object.define_singleton_method(name, original)
  end
end
