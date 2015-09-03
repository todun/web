#!/bin/bash ../test_wrapper.sh

require_relative 'model_test_base'
require_relative 'DeltaMaker'

class AvatarTests < ModelTestBase

  include TimeNow

  test 'path(avatar)' do
    kata = make_kata
    avatar = kata.start_avatar(Avatars.names)
    assert path_ends_in_slash?(avatar)
    assert path_has_no_adjacent_separators?(avatar)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  test 'attempting to create an Avatar with an invalid name raises RuntimeError' do
    kata = katas[unique_id]
    invalid_name = 'mobilephone'
    assert !Avatars.names.include?(invalid_name)
    assert_raises(RuntimeError) { kata.avatars[invalid_name] }
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "avatar returns kata it was created with" do
    kata = make_kata
    avatar = kata.start_avatar
    assert_equal kata, avatar.kata
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "after avatar is created its sandbox contains each visible_file" do
    kata = make_kata
    avatar = kata.start_avatar
    kata.language.visible_files.each do |filename,content|
      assert_equal content, avatar.sandbox.read(filename)
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  test 'avatar is not active? when it does not exist' do
    kata = katas[unique_id]
    lion = kata.avatars['lion']
    assert !lion.exists?
    assert !lion.active?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'avatar is not active? when it has zero traffic-lights' do
    kata = make_kata
    lion = kata.start_avatar(['lion'])
    assert_equal [ ], lion.lights
    assert !lion.active?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'avatar is active? when it has one traffic-light' do
    kata = make_kata
    lion = kata.start_avatar(['lion'])
    stub_test(lion,1)
    assert_equal 1, lion.lights.length
    assert lion.active?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'exists? is true when dir exists and name is in Avatar.names' do
    kata = katas[unique_id]
    lion = kata.avatars['lion']
    assert !lion.exists?
    lion.dir.make
    assert lion.exists?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'after avatar is started its visible_files are ' +
       ' the language visible_files,' +
       ' the exercse instructions,' +
       ' and empty output' do
    kata = make_kata
    language = kata.language
    avatar = kata.start_avatar
    language.visible_files.each do |filename,content|
      assert avatar.visible_files.keys.include?(filename)
      assert_equal avatar.visible_files[filename], content
    end
    assert avatar.visible_files.keys.include? 'instructions'
    assert avatar.visible_files['instructions'].include? kata.exercise.instructions
    assert avatar.visible_files.keys.include? 'output'
    assert_equal '',avatar.visible_files['output']
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'avatar creation saves' +
          ' each visible_file into sandbox/,' +
          ' and empty increments.json into avatar/' do
    kata = make_kata
    avatar = kata.start_avatar
    kata.language.visible_files.each do |filename,content|
      assert_equal content, avatar.sandbox.read(filename)
    end
    assert_equal [ ], JSON.parse(avatar.read('increments.json'))
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - -

  test 'after test() output-file is saved in sandbox/' +
       ' and output is inserted into the visible_files' do
    kata = make_kata
    avatar = kata.start_avatar
    visible_files = avatar.visible_files
    assert visible_files.keys.include?('output')
    assert_equal '',visible_files['output']

    runner.stub_output(expected='helloWorld')
    delta,visible_files = *DeltaMaker.new(avatar).test_args
    _,output = avatar.test(delta, visible_files)

    assert visible_files.keys.include?('output')
    assert_equal expected, output
    assert_equal expected, visible_files['output']
    assert_equal expected, avatar.sandbox.read('output')
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test() on master cyber-dojo.sh results in standard output' +
       ' with no ALERT, and no modification to any cyber-dojo.sh' do
    kata = make_kata(unique_id, 'Java-JUnit')
    avatar = kata.start_avatar
    master = avatar.visible_files[cyber_dojo_sh]

    runner.stub_output(expected = 'no alarms and no surprises')
    delta,visible_files = *DeltaMaker.new(avatar).test_args
    _,output = avatar.test(delta, visible_files)

    assert_equal expected, output
    assert_equal expected, visible_files['output']
    assert_equal expected, avatar.visible_files['output']
    assert_equal expected, avatar.sandbox.read('output')
    assert_equal master, visible_files[cyber_dojo_sh]
    assert_equal master, avatar.visible_files[cyber_dojo_sh]
    assert_equal master, avatar.sandbox.read(cyber_dojo_sh)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test() on commented master cyber-dojo.sh results in standard output' +
       ' with no ALERT, and no modification to any cyber-dojo.sh' do
    kata = make_kata(unique_id, 'Java-JUnit')
    avatar = kata.start_avatar
    maker = DeltaMaker.new(avatar)
    master = maker.was[cyber_dojo_sh]
    maker.change_file(cyber_dojo_sh, commented(master))

    runner.stub_output(expected = 'no alarms and no surprises')
    delta,visible_files = *maker.test_args
    _,output = avatar.test(delta,visible_files)

    assert_equal expected, output
    assert_equal expected, visible_files['output']
    assert_equal expected, avatar.visible_files['output']
    assert_equal expected, avatar.sandbox.read('output')

    assert_equal commented(master), visible_files[cyber_dojo_sh]
    assert_equal commented(master), avatar.visible_files[cyber_dojo_sh]
    assert_equal commented(master), avatar.sandbox.read(cyber_dojo_sh)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test() sees changed cyber-dojo.sh file and appends' +
       ' info plus commented master version to cyber-dojo.sh' +
       ' and prepends an alert to the output. And it does all' +
       ' this only *once*' do
    kata = make_kata(unique_id, 'Java-JUnit')
    avatar = kata.start_avatar
    language = avatar.kata.language
    master = avatar.visible_files[cyber_dojo_sh]
    assert master.split.size > 1

    maker = DeltaMaker.new(avatar)
    maker.change_file(cyber_dojo_sh, first_content = "hello\nworld")
    radiohead = 'no alarms and no surprises'
    runner.stub_output(radiohead)
    delta, visible_files = *maker.test_args
    _,output = avatar.test(delta, visible_files)

    separator = "\n\n"
    expected_output = language.output_alert + separator + radiohead
    assert_equal expected_output,output

    appended_commented_master =
      first_content +
      separator +
      language.cyber_dojo_sh_alert +
      separator +
      commented(master)

    saved_cyber_dojo_sh = avatar.sandbox.read('cyber-dojo.sh')
    assert_equal appended_commented_master, saved_cyber_dojo_sh

    returned_cyber_dojo_sh = visible_files[cyber_dojo_sh]
    assert_equal appended_commented_master, returned_cyber_dojo_sh

    manifested_cyber_dojo_sh = avatar.visible_files[cyber_dojo_sh]
    assert_equal appended_commented_master, manifested_cyber_dojo_sh

    # --- only once ---

    runner.stub_output(radiohead)
    maker = DeltaMaker.new(avatar)
    delta, visible_files = *maker.test_args
    _,output = avatar.test(delta, visible_files)

    assert_equal radiohead,output, 'no ALERT prefixes this time'

    saved_cyber_dojo_sh = avatar.sandbox.read('cyber-dojo.sh')
    assert_equal appended_commented_master, saved_cyber_dojo_sh

    returned_cyber_dojo_sh = visible_files[cyber_dojo_sh]
    assert_equal appended_commented_master, returned_cyber_dojo_sh

    manifested_cyber_dojo_sh = avatar.visible_files[cyber_dojo_sh]
    assert_equal appended_commented_master, manifested_cyber_dojo_sh
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test() does NOT append commented master version to cyber-dojo.sh' +
       ' nor prepends an alert to the output when cyber-dojo.sh is' +
       ' stripped version of one-liner' do
    kata = make_kata(unique_id, 'C (gcc)-assert')
    avatar = kata.start_avatar
    language = avatar.kata.language
    master = avatar.visible_files[cyber_dojo_sh]
    assert master.split.size === 2
    stripped_master = master.strip
    assert stripped_master.split("\n").size === 1

    runner.stub_output(radiohead = 'no alarms and no surprises')
    maker = DeltaMaker.new(avatar)
    maker.change_file(cyber_dojo_sh, stripped_master)
    delta, visible_files = *maker.test_args
    _,output = avatar.test(delta, visible_files)

    expected_output = radiohead
    assert_equal expected_output,output

    saved_cyber_dojo_sh = avatar.sandbox.read(cyber_dojo_sh)
    assert_equal stripped_master, saved_cyber_dojo_sh

    returned_cyber_dojo_sh = visible_files[cyber_dojo_sh]
    assert_equal stripped_master, returned_cyber_dojo_sh

    manifested_cyber_dojo_sh = avatar.visible_files[cyber_dojo_sh]
    assert_equal stripped_master, manifested_cyber_dojo_sh
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test() saves changed makefile with leading spaces converted to tabs' +
       ' and these changes are made to the visible_files parameter too' +
       ' so they also occur in the manifest file' do
    kata = make_kata
    avatar = kata.start_avatar
    filenames = avatar.visible_files.keys
    assert filenames.include? makefile

    runner.stub_output('hello')
    maker = DeltaMaker.new(avatar)
    maker.change_file(makefile, makefile_with_leading_spaces)
    delta, visible_files = *maker.test_args
    avatar.test(delta, visible_files)

    assert_equal makefile_with_leading_tab, avatar.sandbox.read(makefile)
    assert_equal makefile_with_leading_tab, visible_files[makefile]
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test() saves *new* makefile with leading spaces converted to tabs' +
       ' and these changes are made to the visible_files parameter too' +
       ' so they also occur in the manifest file' do
    kata = make_kata
    avatar = kata.start_avatar
    filenames = avatar.visible_files.keys
    assert filenames.include? makefile

    runner.stub_output('hello')
    maker = DeltaMaker.new(avatar)
    maker.delete_file(makefile)
    delta, visible_files = *maker.test_args
    avatar.test(delta, visible_files)

    refute visible_files.keys.include? makefile
    filenames = avatar.visible_files.keys
    refute filenames.include? makefile

    runner.stub_output('hello')
    maker = DeltaMaker.new(avatar)
    maker.new_file(makefile, makefile_with_leading_spaces)
    delta, visible_files = *maker.test_args
    avatar.test(delta, visible_files)

    assert_equal makefile_with_leading_tab, avatar.sandbox.read(makefile)
    assert_equal makefile_with_leading_tab, visible_files[makefile]
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test():delta[:changed] files are saved' do
    kata = make_kata
    language = kata.language
    avatar = kata.start_avatar
    code_filename = 'hiker.c'
    test_filename = 'hiker.tests.c'
    filenames = language.visible_files.keys
    [code_filename,test_filename].each {|filename| assert filenames.include? filename }
    visible_files = {
      code_filename => 'changed content for code file',
      test_filename => 'changed content for test file',
      'cyber-dojo.sh' => 'make'
    }
    delta = {
      :changed => [ code_filename, test_filename ],
      :unchanged => [ ],
      :deleted => [ ],
      :new => [ ]
    }
    delta[:changed].each do |filename|
      assert_equal language.visible_files[filename], avatar.sandbox.read(filename)
      assert_not_equal language.visible_files[filename], visible_files[filename]
    end
    runner.stub_output('')
    avatar.test(delta, visible_files)
    delta[:changed].each do |filename|
      assert_equal visible_files[filename], avatar.sandbox.read(filename)
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test():delta[:unchanged] files are not saved' do
    kata = make_kata
    language = kata.language
    avatar = kata.start_avatar
    code_filename = 'abc.c'
    test_filename = 'abc.tests.c'
    filenames = language.visible_files.keys
    [code_filename,test_filename].each {|filename| assert !filenames.include?(filename) }
    visible_files = {
      code_filename => 'changed content for code file',
      test_filename => 'changed content for test file',
      'cyber-dojo.sh' => 'make'
    }
    delta = {
      :changed => [ ],
      :unchanged => [ code_filename, test_filename ],
      :deleted => [ ],
      :new => [ ]
    }
    runner.stub_output('')
    avatar.test(delta, visible_files)
    delta[:unchanged].each do |filename|
      assert !avatar.sandbox.dir.exists?(filename)
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'test():delta[:new] files are saved and git added' do
    kata = make_kata
    avatar = kata.start_avatar
    language = kata.language
    new_filename = 'ab.c'
    visible_files = {
      new_filename => 'content for new code file',
    }
    delta = {
      :changed => [ ],
      :unchanged => [ ],
      :deleted => [ ],
      :new => [ new_filename ]
    }

    assert !git_log_include?(avatar.sandbox.path, ['add', "#{new_filename}"])
    delta[:new].each do |filename|
      assert !avatar.sandbox.dir.exists?(filename)
    end

    runner.stub_output('')
    avatar.test(delta, visible_files)

    assert git_log_include?(avatar.sandbox.path, ['add', "#{new_filename}"])
    delta[:new].each do |filename|
      assert avatar.sandbox.dir.exists?(filename)
      assert_equal visible_files[filename], avatar.sandbox.read(filename)
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "test():delta[:deleted] files are git rm'd" do
    kata = make_kata
    avatar = kata.start_avatar
    visible_files = {
      'untitled.cs' => 'content for code file',
      'untitled.test.cs' => 'content for test file',
      'cyber-dojo.sh' => 'gmcs'
    }
    delta = {
      :changed => [ 'untitled.cs' ],
      :unchanged => [ 'cyber-dojo.sh', 'untitled.test.cs' ],
      :deleted => [ 'wibble.cs' ],
      :new => [ ]
    }

    runner.stub_output('')
    avatar.test(delta, visible_files)

    git_log = git.log[avatar.sandbox.path]
    assert git_log.include?([ 'rm', 'wibble.cs' ]), git_log.inspect
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - -

  test 'tag.diff' do
    kata = make_kata
    lion = kata.start_avatar(['lion'])
    fake_three_tests(lion)
    manifest = JSON.unparse({
      'hiker.c' => '#include "hiker.h"',
      'hiker.h' => '#ifndef HIKER_INCLUDED_H\n#endif',
      'output' => 'unterminated conditional directive'
    })
    filename = 'manifest.json'
    git.spy(lion.dir.path,'show',"#{3}:#{filename}",manifest)
    stub_diff = [
      "diff --git a/sandbox/hiker.h b/sandbox/hiker.h",
      "index e69de29..f28d463 100644",
      "--- a/sandbox/hiker.h",
      "+++ b/sandbox/hiker.h",
      "@@ -1 +1,2 @@",
      "-#ifndef HIKER_INCLUDED",
      "\\ No newline at end of file",
      "+#ifndef HIKER_INCLUDED_H",
      "+#endif",
      "\\ No newline at end of file"
    ].join("\n")
    git.spy(lion.dir.path,
      'diff',
      '--ignore-space-at-eol --find-copies-harder 2 3 sandbox',
      stub_diff)

    tags = lion.tags
    actual = lion.diff(2,3) #tags[2].diff(3)
    expected =
    {
      "hiker.h" =>
      [
        { :type => :section, :index => 0 },
        { :type => :deleted, :line => "#ifndef HIKER_INCLUDED", :number => 1 },
        { :type => :added,   :line => "#ifndef HIKER_INCLUDED_H", :number => 1 },
        { :type => :added,   :line => "#endif", :number => 2 }
      ],
      "hiker.c" =>
      [
        { :line => "#include \"hiker.h\"", :type => :same, :number => 1 }
      ],
      "output" =>
      [
        { :line => "unterminated conditional directive", :type => :same, :number => 1 }
      ]
    }
    assert_equal expected, actual
  end

  #- - - - - - - - - - - - - - - - - - -

  def makefile_with_leading_tab
    makefile_with_leading("\t")
  end

  def makefile_with_leading_spaces
    makefile_with_leading(' '+' ')
  end

  def makefile_with_leading(s)
    tab = "\t"
    [
      "CFLAGS += -I. -Wall -Wextra -Werror -std=c11",
      "test: makefile $(C_FILES) $(COMPILED_H_FILES)",
      s + "@gcc $(CFLAGS) $(C_FILES) -o $@"
    ].join("\n")
  end

  #- - - - - - - - - - - - - - - - - - -

  def fake_three_tests(avatar)
    incs =
    [
      {
        'colour' => 'red',
        'time' => [2014, 2, 15, 8, 54, 6],
        'number' => 1
      },
      {
        'colour' => 'green',
        'time' => [2014, 2, 15, 8, 54, 34],
        'number' => 2
      },
      {
        'colour' => 'green',
        'time' => [2014, 2, 15, 8, 55, 7],
        'number' => 3
      }
    ]
    avatar.dir.write('increments.json', incs)
  end

  #- - - - - - - - - - - - - - - - - - -

  def git_log_include?(path,find)
    git.log[path].any?{|entry| entry == find}
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def commented(lines)
    lines.split("\n").map{ |line| '# ' + line }.join("\n")
  end

  def cyber_dojo_sh; 'cyber-dojo.sh'; end

  def makefile; 'makefile'; end

end
