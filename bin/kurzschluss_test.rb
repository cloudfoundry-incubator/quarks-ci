require_relative 'kurzschluss'
require 'test/unit'

class TestSimpleNumber < Test::Unit::TestCase
  setup do
    @code = [
      'b.go',
      'a.java'
    ]
    @docs = [
      'docs/test.md'
    ]
    @mixed = [
      'docs/test.md',
      'b.go'
    ]
  end

  # SUCCEED_UNLESS_CHANGES_BEYOND: '^docs/.*\.md'
  def test_full_match
    assert_false(full_match('.*\.md$', @code))
    assert_true(full_match('.*\.md$', @docs))
    assert_false(full_match('.*\.md$', @mixed))
  end

  # SUCCEED_UNLESS_CHANGES_CONTAIN: '.*\.go$'
  def test_no_match
    assert_false(no_match('.*\.go$', @code))
    assert_true(no_match('.*\.go$', @docs))
    assert_false(no_match('.*\.go$', @mixed))
  end

end
