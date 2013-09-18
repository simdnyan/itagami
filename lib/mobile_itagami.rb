# coding: utf-8

class MobileItagami

  BASE_URL     = 'rakuten-sec.co.jp'
  LOGIN_URL    = 'https://mobile.' + BASE_URL
  LOGIN_ACTION =  LOGIN_URL + '/login.do'

  TOP_PAGE_TITLE = "楽天証券 お取引ﾍﾟｰｼﾞ"

  def initialize(log_file = "log/mobile_itagami.log")
    @agent  = Mechanize.new
    #@agent.log                 = Logger.new(log_file)
    #@agent.log.level           = Logger::INFO
    @agent.user_agent_alias    = 'iPhone'
    @agent.follow_meta_refresh = true
    @agent.redirect_ok         = true
    @agent.redirection_limit   = 3

    @logger = Logger.new(log_file)
  end

  def login
    ENV["EDITOR"] ||= "vim"
    user = Pit.get(BASE_URL, :require => {"id" => "id", "password" => "password"})
    @agent.get(LOGIN_URL)
    @agent.page.form_with(:action => LOGIN_ACTION){ |form|
      form.field_with(:name => 'loginId').value = user["id"]
      form.field_with(:name => 'loginPassword').value  = user["password"]
      form.click_button
    }

    raise unless @agent.page.title == TOP_PAGE_TITLE

    @logger.info('login success.')
    log_location
  end

  def buy_immediately(stock, unit)
    go_buy(stock)
    # 余力
    #body = @agent.page.body.toutf8.gsub(/\&nbsp;/, ' ')
    #/<br>現値:.([0-9,]+)<font/ =~ body
    #current_price = $1.to_integer
    #yoryoku = @agent.page.at("//div[@align='right']").text.to_integer
    #raise if current_price * unit > yoryoku

    input_trade_form(:buy, stock, unit)

    raise unless @agent.page.title == '現物買い注文/受付完了（通常）'

    @logger.info("buy_immediately success.")

  rescue
    @logger.error("buy_immediately faild. :#{@agent.page.at("//font").text}")
  end

  def sell_immediately(stock, unit)
    go_sell(stock)
    input_trade_form(:sell, stock, unit)

    unless @agent.page.title == '現物売り注文/受付完了（通常）' then
      message = @agent.page.at("//font").text
      raise if message == 'お客様の売付可能余力が不足しています。'
    end

    @logger.info("sell_immediately success.")
  rescue
    @logger.error("sell_immediately faild. :#{@agent.page.at("//font").text}")
  end

  def input_trade_form(method, stock, unit)

    user = Pit.get(BASE_URL, :require => {"pin" => "pin"})

    # 通常注文
    #@agent.page.forms.slice(1){ |form|
    #  form.field_with(:name => '0'){ |list|
    #    list.option_with(:text => '通常注文').select
    #  }
    #  form.click_button
    #}

    form = @agent.page.forms.last
    # 数量
    form.field_with(:name => '0').value = unit
    # 価格 => 成行
    form.radiobutton_with(:value => 'nariyuki').check
    # 執行条件 => 本日中
    form.field_with(:name => '3').option_with(:text => '本日中').select
    # 口座 => 特定
    if method == :buy then
      form.radiobutton_with(:value => 'tokutei').check
    end
    # 取引暗証番号
    pin_num = {:buy => '5', :sell => '4'}
    form.field_with(:name => pin_num[method]).value = user["pin"]
    # 確認画面を省略
    form.radiobutton_with(:value => 'noConfirmation').check

    form.click_button
    log_location

    check_insider
  end

  def check_insider
    # インサイダー情報確認 => "該当しない"
    if @agent.page.title == 'ｲﾝｻｲﾀﾞｰ情報確認' then
      @agent.page.link_with(:text => '該当しない').click
      log_location
    end
    # 取引理由確認 => "資産形成、長期保有"
    if @agent.page.title == '取引理由確認' then
      form = @agent.page.forms.last
      form.radiobutton_with(:value => '1').check
      form.click_button
      log_location
    end
  end

  def get_stock_info(stock)
    search(stock)
    at   = Time.now
    body = @agent.page.body.toutf8.gsub(/\&nbsp;/, ' ')

    # 現在値
    # "<br>現: 0‐"
    # "<br>現:C1,000<font"
    # "<br>現:H1,000<font"
    # "<br>現:L1,000<font"
    # "<br>現:*1,000<font"
    # "<br>現: 1,000<font"
    /<br>現:[CHL\* ]([0-9,]+)[(‐)|(<font)]/ =~ body
    current_price = $1.to_integer
    # 時刻
    /<br>\(([0-9:\&nsbp;\/ ]+)\)<br>/ =~ body
    trade_time = Time.parse($1)
    current = (current_price == 0) ? nil : {:price => current_price, :time => trade_time}

    # 売気配, 買気配
    ask, bid = ['売気配', '買気配'].map{ |s|
      /<br>#{s}:([0-9,]+)<br>/ =~ body
      $1.to_integer
    }

    # 始値, 高値, 安値
    opening, high, low = ['始', '高', '安'].map{ |s|
      /<br>#{s}([0-9,]+)円\(([0-9:]+)\)<br>/ =~ body
      if $1 and $2 then
        price = $1.to_integer
        time  = Time.parse("#{trade_time.strftime("%Y/%m/%d ")} #{$2}")
        {:price => price, :time => time}
      else
        nil
      end
    }
    # 出来高
    /<br>出来高:([0-9,]+)株/ =~ body
    dekidaka = $1.to_integer

    # 単元
    /<br>単([0-9,]+)株/ =~ body
    unit = $1.to_integer

    return {
             :time     => at,
             :stock    => stock,
             :current  => current,
             :opening  => opening,
             :high     => high,
             :low      => low,
             :dekidaka => dekidaka,
             :unit     => unit,
           }
  end

  def get_board(stock)
    search(stock)
    time = Time.now
    @agent.page.link_with(:text => "値幅･気配値").click
    log_location

    body = @agent.page.body.toutf8

    board_str = [["売", "買"], ["買", "値幅制限"]].map{ |s|
      />#{s[0]}(.*)<br><br>(<font color=\"red\">)?#{s[1]}/ =~ body
      $1
    }

    table = board_str.each_with_object(/([0-9,|OVER|UNDER]+)円?\/([0-9,]+)株/).map(&:scan)
    ask, bid = table.map do |t|
      result = {:table => []}
      t.each do |p|
        if /OVER|UNDER/ =~ p[0]
          result[p[0].downcase.to_sym] =  p[1].to_integer
        else
          result[:table] << {:price => p[0].to_integer, :volume => p[1].to_integer}
        end
      end
      result
    end

    ask[:over]  = 0 unless ask.has_key?(:over)
    bid[:under] = 0 unless bid.has_key?(:under)

    return {:time => time, :ask => ask, :bid => bid}

  rescue => e
    @logger.error(@agent.page.body.toutf8)
    raise e
  end

  def search(stock)
    go_top
    @agent.page.link_with(:text => "株価検索").click
    log_location

    @agent.page.form_with(:method => "POST"){ |form|
      form.field_with(:name => '0').value = stock
      form.click_button
    }
    log_location
  end

  def is_session_timeout?
    return @agent.page.title == 'ｾｯｼｮﾀｲﾑｱｳﾄ'
  end

  def is_top?
    return @agent.page.title == TOP_PAGE_TITLE
  end

  def go_top
    return if is_top?
    to_top_link = @agent.page.link_with(:text => "ﾄｯﾌﾟへ")
    raise unless to_top_link
    to_top_link.click
    log_location

    login if is_session_timeout?
  rescue
    @logger.error("top page link not found.")
  end

  def go_stock_list
    go_top
    @agent.page.link_with(:text => '保有株式一覧').click
    raise unless @agent.page.at("//div").text == '保有株式一覧'
    log_location
  rescue
    @logger.error("go_stock_list failed.")
  end

  def go_buy(stock)
    go_top
    search(stock)
    @agent.page.link_with(:text => '現物買い注文').click
    log_location
  end

  def go_sell(stock)
    go_top
    @agent.page.link_with(:text => '株式取引').click
    log_location
    @agent.page.link_with(:text => '現物売り注文').click
    log_location

    form = @agent.page.forms.last
    form.field_with(:name => '0').value = stock
    form.click_button
    log_location

    @agent.page.link_with(:text => stock.to_s).click
    log_location
  rescue
    @logger.error("go_sell failed.")
  end

  def logout
    go_top
    @agent.page.link_with(:text => 'ﾛｸﾞｱｳﾄ').click
    raise unless @agent.page.title == 'ﾛｸﾞｱｳﾄ完了'
    log_location
    @logger.info("logout success.")
  rescue
    @logger.error("logout failed.")
  end

  def log_location
    @logger.debug("#{@agent.page.title}|[#{@agent.page.uri}]")
  end

end
