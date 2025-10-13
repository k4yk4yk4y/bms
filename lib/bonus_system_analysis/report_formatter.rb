# frozen_string_literal: true

require "json"
require "securerandom"

module BonusSystemAnalysis
  module ReportFormatter
    def self.format(brakeman_output, rubocop_output, eslint_output)
      report_id = SecureRandom.uuid
      created_at = Time.now.utc.iso8601
      feature_branch = "002-mcp" # Placeholder for now

      vulnerabilities = []

      # Process Brakeman output
      if brakeman_output && !brakeman_output.empty?
        brakeman_json = JSON.parse(brakeman_output)
        brakeman_json["warnings"].each do |warning|
          vulnerabilities << {
            id: "BRAKEMAN-#{SecureRandom.hex(4)}",
            title: warning["warning_type"],
            description: warning["message"],
            severity: map_brakeman_confidence_to_severity(warning["confidence"]),
            location: "#{warning['file']}:#{warning['line']}",
            tool: "Brakeman",
            refactoring_proposal: {
              description: "Review Brakeman documentation for suggested fixes.",
              complexity: "Medium",
              estimated_effort_hours: 2
            }
          }
        end
      end

      # Process RuboCop output
      if rubocop_output && !rubocop_output.empty?
        rubocop_json = JSON.parse(rubocop_output)
        rubocop_json["files"].each do |file|
          file["offenses"].each do |offense|
            vulnerabilities << {
              id: "RUBOCOP-#{SecureRandom.hex(4)}",
              title: offense["cop_name"],
              description: offense["message"],
              severity: map_rubocop_severity_to_severity(offense["severity"]),
              location: "#{file['path']}:#{offense['location']['line']}",
              tool: "RuboCop",
              refactoring_proposal: {
                description: "Consult RuboCop documentation for the specific cop and apply suggested refactoring.",
                complexity: "Low",
                estimated_effort_hours: 1
              }
            }
          end
        end
      end

      # Process ESLint output
      if eslint_output && !eslint_output.empty?
        eslint_json = JSON.parse(eslint_output)
        eslint_json.each do |file|
          file["messages"].each do |message|
            vulnerabilities << {
              id: "ESLINT-#{SecureRandom.hex(4)}",
              title: message["ruleId"],
              description: message["message"],
              severity: map_eslint_severity_to_severity(message["severity"]),
              location: "#{file['filePath']}:#{message['line']}",
              tool: "ESLint",
              refactoring_proposal: {
                description: "Refer to ESLint rule documentation for resolution.",
                complexity: "Low",
                estimated_effort_hours: 1
              }
            }
          end
        end
      end

      report = {
        report_id: report_id,
        created_at: created_at,
        feature_branch: feature_branch,
        summary: "Architectural analysis of the bonus system.",
        vulnerabilities: vulnerabilities
      }

      JSON.pretty_generate(report)
    end

    def self.map_brakeman_confidence_to_severity(confidence)
      case confidence
      when "High" then "Critical"
      when "Medium" then "High"
      when "Weak" then "Medium"
      else "Low"
      end
    end

    def self.map_rubocop_severity_to_severity(severity)
      case severity
      when "fatal" then "Critical"
      when "error" then "High"
      when "warning" then "Medium"
      when "convention" then "Low"
      when "refactor" then "Low"
      else "Low"
      end
    end

    def self.map_eslint_severity_to_severity(severity)
      case severity
      when 2 then "High" # ESLint error
      when 1 then "Medium" # ESLint warning
      else "Low"
      end
    end
  end
end
