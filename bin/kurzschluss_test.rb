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

    assert_false(full_match('^(docs/.*\.md|website/.*|\.github/.*)', @code))
    assert_true(full_match('^(docs/.*\.md|website/.*|\.github/.*)', @docs))
    assert_false(full_match('^(docs/.*\.md|website/.*|\.github/.*)', @mixed))
    assert_true(full_match('^(docs/.*\.md|website/.*|\.github/.*)', %w{website/sdf}))
    assert_true(full_match('^(docs/.*\.md|website/.*|\.github/.*)', %w{.github/sdf}))
    assert_true(full_match('^(docs/.*\.md|website/.*|\.github/.*)', %w{docs/sdf.md}))
    assert_false(full_match('^(docs/.*\.md|website/.*|\.github/.*)', %w{website}))
    assert_false(full_match('^(docs/.*\.md|website/.*|\.github/.*)', %w{.github}))
    assert_false(full_match('^(docs/.*\.md|website/.*|\.github/.*)', %w{docs/sdf.}))

    assert_false(full_match('^(docs/.*\.md|website/.*|\.github/.*)',
                            %w(.github/workflows/ci.yaml go.mod go.sum pkg/kube/controllers/boshdeployment/deployment_reconciler.go pkg/kube/controllers/boshdeployment/link_infos.go)))

  end

  # SUCCEED_UNLESS_CHANGES_CONTAIN: '.*\.go$'
  def test_no_match
    assert_false(no_match('.*\.go$', @code))
    assert_true(no_match('.*\.go$', @docs))
    assert_false(no_match('.*\.go$', @mixed))
  end

end
