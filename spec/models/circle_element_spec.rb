require 'spec_helper'

describe CircleElement do

  describe "attach_label_to_element" do 
    
    it "attaches the label to the element" do 
      dependency = Dependency.new 
      dependency.name = "junit"
      dependency.version = "1.0.1"
      element = CircleElement.new 
      CircleElement.send( :public, *CircleElement.attach_label_to_element(nil, nil) )
      CircleElement.attach_label_to_element( element, dependency )
      element.text.should eql("junit:1.0.1")
    end

  end
  
end