module RefersHelper

  def check_refer
    refer_name = params['refer']
    return nil if refer_name.nil?
    refer = Refer.get_by_name refer_name
    return nil if refer.nil?
    refer.count = refer.count + 1
    refer.save
    cookies.permanent.signed[:veye_refer] = refer_name
  end

end
