# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

# Issue #167: `just workshop-restore-gold` ran `git checkout blog/config/`, reverting the
# attendee's own credentials.yml.enc (regenerated to match their master.key) to the
# maintainer's committed one. Every Step 6 command that boots Rails in production then
# failed with ActiveSupport::MessageEncryptor::InvalidMessage.
class WorkshopTimeMachineTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)

  def with_scratch_repo
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "bin"))
      FileUtils.mkdir_p(File.join(dir, "blog", "config"))
      FileUtils.cp(File.join(REPO_ROOT, "bin", "workshop_time_machine.rb"), File.join(dir, "bin"))
      File.write(File.join(dir, "blog/config/database.yml"), "gold: true\n")
      File.write(File.join(dir, "blog/config/credentials.yml.enc"), "MAINTAINER-ENCRYPTED\n")
      git = ->(*args) { system("git", "-C", dir, "-c", "user.email=t@example.com", "-c", "user.name=t", *args, out: File::NULL, err: File::NULL) }
      git.call("init", "-q")
      git.call("add", "-A")
      git.call("commit", "-q", "-m", "gold")
      yield dir
    end
  end

  def restore_gold(dir)
    Open3.capture3("ruby", File.join(dir, "bin", "workshop_time_machine.rb"), "restore-gold")
  end

  def test_restore_gold_reverts_overlay_files
    with_scratch_repo do |dir|
      File.write(File.join(dir, "blog/config/database.yml"), "gold: false # stage overlay\n")
      _out, err, status = restore_gold(dir)
      assert status.success?, err
      assert_equal "gold: true\n", File.read(File.join(dir, "blog/config/database.yml"))
    end
  end

  def test_restore_gold_keeps_the_attendees_credentials
    with_scratch_repo do |dir|
      File.write(File.join(dir, "blog/config/credentials.yml.enc"), "ATTENDEE-ENCRYPTED\n")
      File.write(File.join(dir, "blog/config/database.yml"), "gold: false\n")
      _out, err, status = restore_gold(dir)
      assert status.success?, err
      assert_equal "ATTENDEE-ENCRYPTED\n", File.read(File.join(dir, "blog/config/credentials.yml.enc")),
                   "restore-gold must not overwrite the attendee's credentials.yml.enc (paired with their master.key)"
      assert_equal "gold: true\n", File.read(File.join(dir, "blog/config/database.yml")),
                   "other config files must still be restored"
    end
  end
end
