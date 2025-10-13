# frozen_string_literal: true

require "fileutils"
require "open3" # Add this line
require_relative "../bonus_system_analysis/report_formatter"

namespace :bonus_system do
  desc "Analyzes the bonus system for vulnerabilities and code quality issues."
  task :analyze do
    puts "Starting architectural analysis..."
    FileUtils.mkdir_p("tmp/analysis_reports")

    puts "Running Brakeman..."
    brakeman_output = begin
      stdout, stderr, status = Open3.capture3("brakeman --force --quiet -f json")
      raise "Brakeman command failed: #{stderr}" unless status.success?
      stdout
    rescue StandardError => e
      warn "Brakeman failed: #{e.message}"
      ""
    end

    puts "Running RuboCop..."
    rubocop_output = begin
      stdout, stderr, status = Open3.capture3("rubocop --format json app/")
      # RuboCop returns non-zero exit code when issues are found, which is expected
      # We only treat it as failure if there's actual stderr output or if stdout is empty
      if stderr && !stderr.empty?
        raise "RuboCop command failed: #{stderr}"
      elsif stdout.empty?
        raise "RuboCop produced no output"
      end
      stdout
    rescue StandardError => e
      warn "RuboCop failed: #{e.message}"
      ""
    end

    puts "Running ESLint..."
    eslint_output = begin
      stdout, stderr, status = Open3.capture3("npx eslint --format json app/javascript/")
      # ESLint returns non-zero exit code when issues are found, which is expected
      # We only treat it as failure if there's actual stderr output or if stdout is empty
      if stderr && !stderr.empty?
        raise "ESLint command failed: #{stderr}"
      elsif stdout.empty?
        raise "ESLint produced no output"
      end
      stdout
    rescue StandardError => e
      warn "ESLint failed: #{e.message}"
      ""
    end

    puts "Formatting report..."
    formatted_report = BonusSystemAnalysis::ReportFormatter.format(brakeman_output, rubocop_output, eslint_output)
    File.write("tmp/analysis_reports/bonus_system_report.json", formatted_report)
    puts "Analysis complete. Report saved to tmp/analysis_reports/bonus_system_report.json"
  end
end
