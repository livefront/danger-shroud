require 'nokogiri'

module Danger

  # Parse a Jacoco report to enforce code coverage on CI. Results are passed out as a table in markdown.
  #
  # Shroud depends on having a Jacoco coverage report generated for your project. For Android projects, 
  # [jacoco-android-gradle-plugin](https://github.com/arturdm/jacoco-android-gradle-plugin) works well. 
  #
  # @example Running shroud with default values
  #
  #          # Report coverage of modified files, fail if either total project coverage
  #          # or any modified file's coverage is under 90%
  #          shroud.report 'path/to/jacoco/report.xml'
  #
  # @example Running shroud with custom coverage thresholds
  #
  #          # Report coverage of modified files, fail if total project coverage is under 80%,
  #          # or if any modified file's coverage is under 95%
  #          shroud.report 'path/to/jacoco/report.xml', 80, 95
  #
  # @example Warn on builds instead of fail
  #
  #          # Report coverage of modified files the same as the above example, except the
  #          # builds will only warn instead of fail if below thresholds
  #          shroud.report 'path/to/jacoco/report.xml', 80, 95, false
  #          
  # @tags android, jacoco, coverage
  #
  class DangerShroud < Plugin

    # Report coverage on diffed files, as well as overall coverage.
    #
    # @param   [String] file
    #          file path to a Jacoco xml coverage report.
    #
    # @param   [Integer] totalProjectThreshold
    #          defines the required percentage of total project coverage for a passing build.
    #          default 90.
    #
    # @param   [Integer] modifiedFileThreshold
    #          defines the required percentage of files modified in a PR for a passing build.
    #          default 90.
    #
    # @param   [Boolean] failIfUnderThreshold
    #          if true, will fail builds that are under the provided thresholds. if false, will only warn.
    #          default true.
    #
    # @return  [void]
    def report(file, totalProjectThreshold = 90, modifiedFileThreshold = 90, failIfUnderThreshold = true)
      raise "Please specify file name." if file.empty?
      raise "No jacoco xml report found at #{file}" unless File.exist? file
      rawXml = File.read(file)
      parsedXml = Nokogiri::XML.parse(rawXml)
      totalInstructionCoverage = parsedXml.xpath("/report/counter[@type='INSTRUCTION']")
      missed = totalInstructionCoverage.attr("missed").value.to_i
      covered = totalInstructionCoverage.attr("covered").value.to_i
      total = missed + covered
      coveragePercent = (covered / total.to_f) * 100

      # get array of files names touched by this PR (modified + added)
      touchedFileNames = @dangerfile.git.modified_files.map { |file| File.basename(file) }
      touchedFileNames += @dangerfile.git.added_files.map { |file| File.basename(file) }

      # used to later report files that were modified but not included in the jacoco report
      fileNamesNotInJacocoReport = []

      # hash for keeping track of coverage per filename: {filename => coverage percent}
      touchedFilesHash = {}

      touchedFileNames.each do |touchedFileName|
        xmlForFileName = parsedXml.xpath("//class[@sourcefilename='#{touchedFileName}']/counter[@type='INSTRUCTION']")

        if (xmlForFileName.length > 0)
          missed = 0
          covered = 0
          xmlForFileName.each do |classCountXml|
            missed += classCountXml.attr("missed").to_i
            covered += classCountXml.attr("covered").to_i
          end
          touchedFilesHash[touchedFileName] = (covered.to_f / (missed + covered)) * 100
        else
          fileNamesNotInJacocoReport << touchedFileName
        end
      end

      puts "Here are unreported files"
      puts fileNamesNotInJacocoReport.to_s
      puts "Here is the touched files coverage hash"
      puts touchedFilesHash

      output = "## 🧛 Project Code Coverage: **`#{'%.2f' % coveragePercent}%`**\n"

      output << "### Coverage of Modified Files:\n"
      output << "File | Coverage\n"
      output << ":-----|:-----:\n"

      # go through each file:
      touchedFilesHash.sort.each do |fileName, coveragePercent|
        output << "`#{fileName}` | **`#{'%.2f' % coveragePercent}%`**\n"

        # warn or fail if under specified file threshold:
        if (coveragePercent < modifiedFileThreshold)
          warningMessage = "Uh oh! #{fileName} is under #{modifiedFileThreshold}% coverage!"
          if (failIfUnderThreshold)
            fail warningMessage
          else 
            warn warningMessage
          end
        end
      end

      output << "### Modified Files Not Found In Coverage Report:\n"
      fileNamesNotInJacocoReport.sort.each do |unreportedFileName| 
        output << "#{unreportedFileName}\n"
      end

      output << '> Codebase cunningly covered by count [Shroud 🧛](https://github.com/livefront/livefront-shroud-android/)'
      markdown output

      # warn or fail if total coverage is under specified threshold
      if (coveragePercent < totalProjectThreshold)
        totalCoverageWarning = "Uh oh! Your project is under #{totalProjectThreshold}% coverage!"
        if (failIfUnderThreshold) 
          fail totalCoverageWarning
        else 
          warn totalCoverageWarning
        end
      end
    end
  end
end
