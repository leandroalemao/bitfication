require 'debugger'

namespace :bitfication do
  desc "Update exchange statistics"
  task :stats => :environment do
    
    
    #if stat doesn't exist, create it
    if Stats.count < 1
      ns = Stats.new
      ns.volume = 0
      ns.phigh = 0
      ns.plow = 0
      ns.pwavg = 0
      ns.save!
    end
    
    
    puts Stats.count
    
    currency = "brl"
    
    @ticker = {
      :high => Trade.with_currency(currency).since_0h.maximum(:ppc),
      :low => Trade.with_currency(currency).since_0h.minimum(:ppc),
      :volume => (Trade.with_currency(currency).since_0h.sum(:traded_btc) || 0),
      :last_trade => Trade.with_currency(currency).count.zero? ? 0 : {
        :at => Trade.with_currency(currency).plottable(currency).last.created_at.to_i,
        :price => Trade.with_currency(currency).plottable(currency).last.ppc
      }
    }
    
    @ticker[:high] = @ticker[:high]==nil ? 0 : @ticker[:high]
    @ticker[:low] = @ticker[:low]==nil ? 0 : @ticker[:low]
    @ticker[:volume] = @ticker[:volume]==nil ? 0 : @ticker[:volume]
    
    # weighted average http://en.wikipedia.org/wiki/Mean#Weighted_arithmetic_mean
    w = 0
    wx = 0
    Trade.with_currency(currency).last_24h.each do |t|
      w += t.traded_btc.to_f
      wx += t.traded_btc.to_f * t.ppc.to_f
    end
    
    if wx != 0 && w != 0
      @ticker[:wavg] = wx / w
    else
      @ticker[:wavg] = 0
    end
    
    # update db
    s = Stats.last
    
    #debugger
    
    s.volume = @ticker[:volume]
    s.phigh = @ticker[:high]
    s.plow = @ticker[:low]
    s.pwavg = @ticker[:wavg]
    s.save
    
  end

end