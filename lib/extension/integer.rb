# coding: utf-8

class Integer
  def to_currency()
    self.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end
