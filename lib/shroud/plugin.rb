require 'nokogiri'

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  class DangerShroud < Plugin

    # Report coverage on diffed files, as well as overall coverage. 
    # 
    # file should reference a jacoco xml coverage report.
    # totalProjectThreshold defines the threshold at which a warning will be emitted on total project coverage. deafult 0.
    # modifiedFileThreshold defines the threshold at which a warning will be emitted on each modified file's coverage. default 0.
    # failIfUnderThreshold when set to true will fail builds that fall under the above thresholds. default is false, which will warn.
    #
    # @return   [void]
    def report(file, totalProjectThreshold = 0, modifiedFileThreshold = 0, failIfUnderThreshold = false)
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
