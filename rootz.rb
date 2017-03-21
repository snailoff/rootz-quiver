module Rootz	
	class InvalidPathError < StandardError
		attr_reader :object

		def initialize object
			@object = object
		end
	end

	class InvalidConfigError < StandardError
		attr_reader :object

		def initialize object
			@object = object
		end
	end

	class Root
		attr_accessor :subject, :navi, :parsed, :created, :redirect_url, :header_image

		def initialize notebook, page

			get_settings

			Rootz.logger.info "notebook : #{notebook}"
			Rootz.logger.info "page : #{page}"
			Rootz.logger.info "@qvlibrary_path : #{@qvlibrary_path}"
			Rootz.logger.info "@default_notebook : #{@default_notebook}"

			@param_notebook = notebook
			@param_page = page

			@root = get_notebook_root @param_notebook
			
			Rootz.logger.info "@root : #{@root}"
		end

		def parse
			Rootz.logger.info
			@parsed = ""		

			list = note_dirs(@root).sort_by{ |f| File.mtime(f) }.reverse
			list.each do |x|
				@parsed += note_view x
			end
	  	end


	  	private

	  	def get_settings
			@settings = JSON.parse File.read("#{File.expand_path "..", __FILE__}/settings")

			qvlibrary = "#{File.expand_path "..", __FILE__}/#{@settings["qvlibrary_path"]}"

			raise Rootz::InvalidConfigError.new self unless File.exist? qvlibrary

			@notebooks_path = @settings["qvlibrary_path"]
			@default_notebook = @settings["default_notebook"]
		end


		def get_notebook_root selected
			json = notebooks @notebooks_path
			json.each do |x|
				if x["name"] == selected
					return "#{@notebooks_path}/#{x["uuid"]}.qvnotebook"					
				end
			end
			raise Rootz::InvalidConfigError.new(self), "no default notebook"
		end 


		def notebooks qvlibrary_path
			Dir.glob("#{qvlibrary_path}/*.qvnotebook/meta.json").map do |x|
				j = JSON.parse File.read(x)
			end
		end

		def note_dirs qvnotebook_path
			Dir.glob("#{qvnotebook_path}/*.qvnote")
		end 

		# title
		# cells
		def note_view qvnote_path
			j = JSON.parse File.read("#{qvnote_path}/content.json")
			
			con = ""
			
			j["cells"].each do |x|
				con += note_cell_view x, qvnote_path
			end
			
			"<content><h1>#{j["title"]}</h1><p>#{con}</p></content>" 

		end

		# type : text, markdown, latex
		# data 
		def note_cell_view cell, qvnote_path
			Rootz.logger.debug "note_cell_view's qvnote_path : #{qvnote_path}"

			if "#{cell["type"]}" == "markdown"
				return render_markdown cell["data"], qvnote_path
			# elsif cell["type"] == "text"
			# 	return cell["data"]
			# elsif cell["type"] == "latex"
			# 	return cell["data"]
			else
				return cell["data"]
			end
		end


	  	def render_markdown plain, qvnote_path
	  		rs = ''
	  		isNoneBreakBlock = false
			isCodeBlock = false
			codeBlockContent = ''
			codeBlockName = ''

	  		plain.split(/\n/).each do |line|
				if isCodeBlock 
					if line =~ /^```(.*)?$/
						lexer = Rouge::Lexer.find codeBlockName

						if lexer 
							source = "\n" + codeBlockContent
							formatter = Rouge::Formatters::HTML.new(css_class: 'highlight')
							rs += formatter.format(lexer.lex(source))
							Rootz.logger.debug "rouge parsing ... (#{codeBlockName})"
						else
							rs += '<div class="codeblock"><pre>' + "\n\n"
							rs += codeBlockContent
							rs += '</pre></div>'
							Rootz.logger.debug "no parsing ... ()"
						end

						isCodeBlock = false
						codeBlockContent = ''
						codeBlockName = ''
						next
					else
						codeBlockContent += line + "\n"
						next
					end
				else
					if line =~ /^```(.*)?$/
						codeBlockName = $1
						Rootz.logger.debug "code block start ... (#{codeBlockName})"
						isCodeBlock = true
						next
					end

				end

				line.strip!

				# if /^@@\s*(?<title>.*)$/ =~ line
				# 	@subject = title
				# 	next
				# end

				if line =~ /^"""/
					isNoneBreakBlock = isNoneBreakBlock ? false : true
					next
				end

				if line =~ /^---/
					rs += "<hr />"
					next
				end
					
				if line =~ /^(\#{1,5})(.*)$/
					rs += "<h#{$1.to_s.length}>#{$2}</h#{$1.to_s.length}>"
					next
				end

				if /``(?<code>.*?)``/ =~ line
					line = "#{special($`)}<span class=\"codeline\">#{safeHtml(code)}</span>#{special($')}"
					line += "<br />" unless isNoneBreakBlock
					rs += line + "\n"
					next
				end

				if /!\[(.*?)\]\(quiver-image-url\/(.*?)\)/ =~ line
					rs += "<img alt=\"#{$1}\" src=\"#{remove_root_prefix(qvnote_path)}/resources/#{$2}\" />"
					next
				end

				special line

				if line =~ /\(\((?:(.*?)(?: (.*?))?)\)\)/
					rs = Extension.new(@config).build($1, $2)
					line.gsub! $&, rs
				end

				line = "<p>#{line}</p>" unless isNoneBreakBlock
				rs += line + "\n"
			end

			"<section>#{rs}</section>"
	  	end

	  	def special str
	  		str.gsub! /''(.*?)''/, "<strong>\\1</strong>"
			str.gsub! /__(.*?)__/, "<u>\\1</u>"
			str.gsub! /\/\/(.*?)\/\//, "<i>\\1</i>"	
			str.gsub! /~~(.*?)~~/, "<del>\\1</del>"
			str
	  	end

	  	def link str
	  		# str.gsub! /:(:[*?)*/, 
	  	end

		def safeHtml str
	  		str.gsub! /</, "&lt;"
	  		str.gsub! />/, "&gt;"
	  		str
	  	end

		def convert_link path
			url = remove_tail(remove_root_prefix(path))
			name = remove_tail(remove_head(remove_root_prefix(basename(path))))

			"<a href=\"#{url}\">#{name}</a>"
		end

		def mtime path 
			datetime = zero_o File.mtime(path).to_s
			"<span class=\"datetime\">#{datetime}</span>"
		end

		def last_dir path
			return "path is not exist!" unless File.exist? path
			tmp = path
			while File.file? tmp
				tmp = File.dirname tmp
			end
			tmp
		end

		def remove_head path
			path.gsub /^\/+/, ''
		end

		def remove_tail path
			path.gsub /(\/|.txt)$/, ''
		end

		def remove_root_prefix path
			return "" if path.empty?

			# rs = path.gsub /#{Rootz::PREFIX_PATH}/, ''
			rs = path.gsub /public/, ''
		end

		def replace_spliter path
			return "" if path.empty?

			rs = path.sub(/^\//, ":: ").gsub(/\//, " : ")
		end

		def basename path
			File.basename path, ".txt"
		end

		def zero_o str
			str.gsub /0/, 'o'
		end
		
	end



	def self.logger
		@logger ||= Logger.new(STDOUT)

		@logger.formatter = proc do |severity, datetime, progname, msg|
			file = caller[4].sub /^.*\/(.*?)$/, "\\1"
			"#{severity.rjust(8)} #{file.rjust(40)} -- : #{msg}\n"
		end

		@logger
	end


	
end