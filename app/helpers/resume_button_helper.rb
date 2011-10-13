module ResumeButtonHelper

  def resume_button(dojo_name, avatar_name, size)
    "<form action='/kata/edit' target='_blank'>" +
      "<input type='hidden' name='dojo_name' id='dojo_name' value='#{dojo_name}'/>" +
      "<input type='hidden' name='avatar' id='avatar' value='#{avatar_name}' />" +    
      "<input type='image'" +
              "src='/images/avatars/#{avatar_name}.jpg'" +
              "width='#{size}'" +
              "height='#{size}'" + "/>" +
    "</form>"    
  end
end
