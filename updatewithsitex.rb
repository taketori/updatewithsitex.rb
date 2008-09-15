#
# updatefromsitex.rb:
#
# Copyright (C) 2008 by taketori <taketori@x10d.jp>
# Distributed under tDiary's.
#


#
# Web上のデータを集めて適切な形式に変更する。
#TODO: 将来的には、このプラグインのプラグインを実行する。
# 「プラグインのプラグイン」を、ufsx_WEBSERVISE.rbというファイル名にして /misc/lib に設置しておくという感じ。
#
def data_collect

	data = []

	data << ufsx_twitter# if @conf['ufsx.twitter']
#	data << ufsx_gcal if @conf['ufsx.gcal']
#	data << ufsx_rtm if @conf['ufsx.rtm']

	to_table(*data)

end

#
# to_table
# HashリストをHTMLのTable Row(TRタグ)に変換する。
#
def to_table( data = [{:desc => "", :to => "", :from => "", :at => ""}] )

	tr = ""
	data.each_with_index{ |item, idx|
		tr << <<-TABLEROW
		<TR>
			<TD class="ufsx_table_line_header">
				<input type=checkbox name="plugin_ufsx_add" value="#{idx}">
			</TD>
			<TD>#{@conf.shorten(item[:desc], 40)}</TD>
			<TD>#{item[:to]}</TD>
			<TD>#{item[:from]}</TD>
			<TD>#{item[:at]}</TD>
		</TR>
		TABLEROW
	}

	tr

end

#
# ufsx_twitter
# twit のうち、(/^_tDiary#/i に該当するtwitをまとめて)、twitした日付の日記にする。
# # "ufsx_サービス名_メソッド名" という関数は暫定。いずれプラグイン&クラスにする。
#
def ufsx_twitter()

# this function is derived from twitter.rb plugin.
#
# twitter.rb $Revision: 1.1 $
# Copyright (C) 2007 Michitaka Ohno <elpeo@mars.dti.ne.jp>
# You can redistribute it and/or modify it under GPL2.

	require 'timeout'
	require 'time'
	require 'open-uri'
	require 'rexml/document'

	user = @conf['twitter.user']
	#pass = @conf['twitter.pass']
	last_updated = @conf['ufsx.twitter.lastupdated'] || (Time.now - 60 * 60 * 24).localtime.strftime('%d+%b+%Y+%H%%3A%M%%3A%S+JST')
	# count: The number of statuses to retrieve. May not be greater than 200.(ref: Twitter's api-documentation)
	count = @conf['ufsx.twitter.count'] || '180'

	ret = []
	xml = nil
	timeout( 5 ) do
		begin
			xml = open( "http://twitter.com/statuses/user_timeline/#{user}.xml?count=#{count}&since=#{last_updated}" ){|f| f.read}
		rescue Exception
		end
	end
	doc = REXML::Document.new( xml ).root if xml
	if doc then
		doc.elements.each( 'status' ) do |e|
			ret << {
				:desc => @conf.to_native( e.elements['text'].text ),
				:to => Time.parse( e.elements['created_at'].text ).localtime.strftime("%Y%m%d"),
				:from => "Twitterby#{e.elements['source']}",
				:at => Time.parse( e.elements['created_at'].text ).localtime
			}
		end
	end

	ret

end

def to_title

end

#
#
def to_html
#TODO: 各プラグインごとに固有の表現形式で、各スタイルに合わせて、内容を変更する。

end

add_edit_proc do |date|

#TODO: プレビューしてもチェックが外れないようにする。
<<-CONFTABLE
<DIV class="ufsx">UpdateFromSiteX: プレビューしたらチェックが外れるのは仕様です。<BR/>
	<TABLE class="ufsx_table">
		<CAPTION class="ufsx_table_caption">You can update from the source(s) below.</CAPTION>
		<TR class="ufsx_table_row_header">
			<TH>add?</TH>
			<TH>description</TH>
			<TH>to</TH>
			<TH>from</TH>
			<TH>is uploaded at</TH>
		</TR>
		#{data_collect}
	</TABLE>
</DIV>
CONFTABLE

end

def ufsx_conf_html(data)
%Q[
#{ufsx_conf_explain}
<p><textarea name="anchor_plugin_data" cols="#{ufsx_conf_cols}" rows="#{ufsx_conf_rows}">#{h data}</textarea></p>
]
end

#TODO: 選択できる。1)最終更新日以降のtwitのみ表示(&日記の対象と)する。2) 1+保存しなかったtwitをufsx.datに保存する。3)最新のN件を表示し、保存したtwitをtwitterから削除していく。
#TODO: 対象となるtwitの正規表現を指定できる。
#TODO: 2.のとき、保存しなかったtwitのIDを、ufsx.datに保存する。
#TODO: 2.3.のとき、管理画面で、保存しなかったtwitの一覧を表示して、日記に追加するか問い合わせる。
#TODO: @replyもうまく表示する。

add_conf_proc( 'ufsx_conf', ufsx_conf_label ) do
	data = ""
	if FileTest.exist?( ufsx_path )
		open( ufsx_path, "r" ) do |i|
			data = i.readlines.join
		end
	end

	if @mode == 'saveconf'
		if @cgi['anchor_plugin_data']
			if FileTest.exist?( ufsx_path )
				open( ufsx_path, "r" ) do |i|
					open( ufsx_path + "~", "w" ) do |o|
						o.print i.readlines
					end
				end
			end

			open( ufsx_path, 'w' ) do |o|
				@cgi["ufsx_plugin_data"].each do |v|
					v.split(/\n/).each do |line|
						o.print line, "\n" if line =~ /\w/
					end
				end
			end
			data = @cgi["anchor_plugin_data"]

		end
	end
 
	ufsx_conf_html(data)
end

=begin
add_update_proc do

#TODO: 追加していくだけでなく、差し替えもできるように。

	#last_update = 
	days_before = 40 # || last_update

	ufsx_cgi = CGI::new
	def ufsx_cgi.referer; nil; end

	ufsx_cgi.params['year'], ufsx_cgi.params['month'], ufsx_cgi.params['day'] = ['2008'],['07'],['12']
#	ufsx_cgi.params['date'] = ['20080712']
	ufsx_cgi.params['title'] = ['']
	ufsx_cgi.params['body'] = ['test diary\nthis is test diary updated from ufsx.']
	ufsx_cgi.params['csrf_protection_key'] = [@conf.options['csrf_protection_key']]

	ufsx_diary = TDiaryAppend::new( ufsx_cgi, '', @conf )

	## save settings


end
=end

=begin
	limit = 40
	cgi = CGI::new
	def cgi.referer; nil; end

	result = ''
	catch( :exit ) {
		@years.keys.sort.reverse_each do |year|
			@years[year].sort.reverse_each do |month|
				cgi.params['date'] = ["#{year}#{month}"]
				m = TDiaryMonth::new( cgi, '', @conf )
				m.diaries.keys.sort.reverse_each do |date_str|
					next if m.diaries[date_str].visible?
					title = m.diaries[date_str].title.gsub( /<[^>]*>/, '' )

					result << %Q|<li><a href="#{@index}#{anchor date_str}">#{date_str}&nbsp;:&nbsp;#{@conf.shorten( title, limit )}</a>|
					if defined?(edit_today_link)
						result << %Q|&nbsp;#{edit_today_link(Date.parse(date_str), "")}|
					end
					result << %Q|</li>\n|
				end
			end
		end
	}

=end
