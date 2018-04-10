# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

class RakeUtils
  def self.git(command)
    puts `git #{command}`
    raise unless $?.success?
  end

  def self.publish_tag(tag, with_extended_requirements: false)
    branch_name = "publish-#{tag}"
    tag_name = "v#{tag}"

    if with_extended_requirements
      branch_name << "-extended"
      tag_name << "-extended"
    end

    git("checkout -b #{branch_name}")

    if with_extended_requirements
      git("commit -a -m 'Extended Read Me'")
    end

    git("tag -a #{tag_name} -m 'Publishing #{tag_name}'")

    git("push origin #{tag_name}")

    puts "Published #{tag_name}"
  end

  def self.write_extended_requirements
    extended_requirements = "- We're selling some items for less than we'd like, so we want to set a minimum price for items whose clearance discount is too low.  For pants and dresses, ensure they don't sell for less than $5. For all other items the minimum price is $2.\n" +
                            "- Users should be able to browse items and see them grouped by status or by batch.\n"

    readme = "README.md"
    lines = File.readlines(readme)

    found_requirements = false
    first_requirement_index = nil

    lines.each_with_index do |line, index|
      if line.starts_with?("# Requirements")
        found_requirements = true
      end

      if (found_requirements && line.starts_with?("- "))
        first_requirement_index = index
        break
      end
    end

    lines.insert(first_requirement_index, extended_requirements)

    File.write(readme, lines.join)
  end
end

desc "Publish ZIP files which can be sent to candidates"
task :publish, [:tag] do |t,args|
  RakeUtils.publish_tag(args.tag)

  RakeUtils.write_extended_requirements

  RakeUtils.publish_tag(args.tag, with_extended_requirements: true)
end

desc "Add a new candidate submission to git"
task :new_submission, [:zip_file,:candidate_name] do |t,args|
  zip_file_path = File.absolute_path(args.zip_file)
  FileUtils.mkdir_p "submission"
  chdir "submission" do
    puts `unzip #{zip_file_path}`
    extracted_dir = Dir["*"].reject { |_| _ =~ /^\_/ }.first # let's hope!
    chdir extracted_dir do
      puts `rsync --exclude .git --exclude tmp --exclude logs --exclude submission --exclude __MACOSX -av  --delete . ../..`
    end
  end
  FileUtils.rm_rf 'submission'

  RakeUtils.git("checkout -b #{args.candidate_name.gsub(/\s/,'-').downcase}")
  RakeUtils.git("add .")
  RakeUtils.git("commit -m '#{args.candidate_name}'")

  puts "After reviewing the commit, push the branch to Github:"
  puts "git push origin #{args.candidate_name.gsub(/\s/,'-').downcase}"
end
