require_relative 'app_lib_test_base'

class FileDeltaMakerTest < AppLibTestBase

  def setup
    super
    set_storer_class('NotUsed')
    set_runner_class('NotUsed')
    set_differ_class('NotUsed')
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  test '89F27F',
  'unchanged files seen as :unchanged' do
    @was = { 'wibble.h' => 3424234 }
    @now = { 'wibble.h' => 3424234 }
    make_delta
    assert_changed []
    assert_unchanged ['wibble.h']
    assert_deleted []
    assert_new []
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  test '89F5A4',
  'changed files seen as :changed' do
    @was = { 'wibble.h' => 52674 }
    @now = { 'wibble.h' => 3424234 }
    make_delta
    assert_changed ['wibble.h']
    assert_unchanged []
    assert_deleted []
    assert_new []
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  test '89FB12',
  'deleted files seen as :deleted' do
    @was = { 'wibble.h' => 52674 }
    @now = {}
    make_delta
    assert_changed []
    assert_unchanged []
    assert_deleted ['wibble.h']
    assert_new []
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  test '89F94B',
  'new files seen as :new' do
    @was = {}
    @now = { 'wibble.h' => 52674 }
    make_delta
    assert_changed []
    assert_unchanged []
    assert_deleted []
    assert_new ['wibble.h']
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  test '89FA92',
  'example with :unchanged, :changed, :deleted, and :new' do
    @was = { 'wibble.h' => 52674, 'wibble.c' => 3424234, 'fubar.h' => -234 }
    @now = { 'wibble.h' => 52674, 'wibble.c' => 46532, 'snafu.c' => -345345 }
    make_delta
    assert_changed ['wibble.c']
    assert_unchanged ['wibble.h']
    assert_deleted ['fubar.h']
    assert_new ['snafu.c']
  end

  private

  def make_delta
    @delta = FileDeltaMaker.make_delta(@was, @now)
  end

  def assert_changed(expected)
    assert_equal expected, @delta[:changed]
  end

  def assert_unchanged(expected)
    assert_equal expected, @delta[:unchanged]
  end

  def assert_deleted(expected)
    assert_equal expected, @delta[:deleted]
  end

  def assert_new(expected)
    assert_equal expected, @delta[:new]
  end

end
