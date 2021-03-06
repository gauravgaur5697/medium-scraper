class ScrapperController < ApplicationController

    # @@BROWSER is a class variable 
    @@BROWSER = Watir::Browser.new :chrome #, headless: true
    @@TAG_NAME = ""

    def show 
    end
    
    # accessing global variable and setting it as URL,
    # to be used by blog_controller to parse that URL
    def bloglink
        @@URL = params[:blog_url]
    end

    # accessing @@TAG_NAME for whole page use
    def tag_name
        @@TAG_NAME = params[:tag_name]
        puts @@TAG_NAME
    end

    # scrapping pages
    def scrapWebPage
        @website = "https://medium.com/tag/"
        @url = @website + "" + @@TAG_NAME
        begin
            @@BROWSER.goto(@url)   
            readPage() # returns list of blogs in JSON format
        rescue => exception
            @@BROWSER.quit
            # again, creating new browser because it might be closed!
            @@BROWSER = Watir::Browser.new :chrome #, headless: true
            return exception.to_json
        end
    end

    # on read_more click
    def nextTenBlogs
        @@BROWSER.scroll.to :bottom # on scrolling, medium makes the ajax request for new blogs!
        sleep 5 # wait for 5 seconds to load the page and extract it!
        readPage()
    end

    # return JSON containing list of blogs
    def readPage 
        @doc = Nokogiri::HTML.parse(@@BROWSER.html)
        # related TAGS
        @tags = []
        @doc.css('.gu.b.ho.hp.hf').each do |related_tag|
            @tags.push({
                :tag_name => related_tag.children.text,
                :tag_link => "https://medium.com/swlh/search?q=python"
            })
        end

        # BLOGS
        @blogs = []
        @doc.css('.ae.lq').each do |blog|
            # author details: name, link to medium
            author_name = blog.css('.as.go.ep.gp.gq.gr.gs.gt.gu.gv.gw.ch.gx').text

            # blog_archieve details


            # blog title image
            img_link = ""
            if blog.css('.progressiveMedia-image.js-progressiveMedia-image').empty?
            else
                img_link = blog.css('.progressiveMedia-image.js-progressiveMedia-image').attribute('data-src').value
            end

            # blog_link


            @blogs.push({
                :title => blog.css('.gu.jf.df.bq.nm.nn.dd.bo.no.np.nq.nr.ns.nt.nu.nv.nw.nx.ny.nz.oa.ob.gg.gz.ha.hb.hc.hd.hf').text,
                :sub_title => blog.css('.as.b.hx.au.gq.hy.gs.gt.hw.gv.gw.av').text,
                :author_name => author_name,
                :reading_time => blog.css('.as.b.hx.cg.av').text,
                :upvotes => blog.css('.as.b.at.au.ch').text.split(' ')[0],
                :img_link => img_link
            })
        end
        
        respond_to do |format|
            format.json{
              render json: {
                "tags": @tags,
                "blogs": @blogs
              }.to_json
            }
        end
    end

    
    # databases

    def insert_histroy
        tag_name = params[:tag_name]
        @history = History.find_by(title: tag_name)
        if @history.nil?
            create_history(tag_name)
        else
            update_history(tag_name)
        end

        get_all_history_json()
    end

    def create_history(tag_name)
        @history = History.create(:title => tag_name, :repeat => 1)
        if @history.save
            # successfully created!
        else
            # catch exception
        end
    end

    def get_all_history_json
        respond_to do |format|
            format.json{
                render json: {
                    "history": get_all_history()
                }.to_json 
            }
        end
    end

    def get_all_history
        @histories = History.all
    end

    def update_history(tag_name)
        History.find_by(title: tag_name).update_attribute(:repeat, @history.repeat + 1)
    end

end
