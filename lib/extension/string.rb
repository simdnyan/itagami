# coding: utf-8

class String
  def to_integer
    self.gsub(/[^\d\.-]/, '').to_i
  end
end
