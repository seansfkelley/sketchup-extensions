module ShakerCabinets
  def self.add_shaker_cabinet
    inputs = UI.inputbox(
      ['Type', 'Carcass Width', 'Carcass Height', 'Carcass Depth', 'Face Border Width', 'Face Depth', 'Face Inset Depth', 'Pull Type'],
      ['Cabinet (RH Pull)', 24.inch, 24.inch, 24.inch, 2.inch, 1.inch, (1.to_f / 2).inch, 'Knob'],
      ['Cabinet (Center Pull)|Cabinet (LH Pull)|Cabinet (RH Pull)|Drawer|Drawer (No Inset)', '', '', '', '', '', '', 'Knob|Pull|None']
    )

    return unless inputs

    type, carcass_width, carcass_height, carcass_depth, face_border_width, face_depth, face_inset_depth, pull_type = inputs

    model = Sketchup.active_model
    model.start_operation("Draw Shaker #{type}")
    cabinet = model.definitions.add("Shaker #{type}")

    ShakerCabinets::draw_carcass cabinet.entities, carcass_width, carcass_height, carcass_depth
    case inputs[0]
    when 'Cabinet (Center Pull)'
      ShakerCabinets::draw_shaker_face cabinet.entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth
    when 'Cabinet (LH Pull)'
      ShakerCabinets::draw_shaker_face cabinet.entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth
    when 'Cabinet (RH Pull)'
      ShakerCabinets::draw_shaker_face cabinet.entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth
    when 'Drawer'
      ShakerCabinets::draw_shaker_face cabinet.entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth
    when 'Drawer (No Inset)'
      ShakerCabinets::draw_simple_face cabinet.entities, carcass_width, carcass_height, face_depth
    end

    model.active_entities.add_instance cabinet, ORIGIN

    model.commit_operation
  end

  def self.draw_carcass(entities, width, height, depth)
    face = entities.add_face [
      [0, 0, 0],
      [width, 0, 0],
      [width, 0, height],
      [0, 0, height],
    ]
    face.reverse! unless face.normal.samedirection?(Y_AXIS)
    face.pushpull depth
  end

  def self.draw_shaker_face(entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth)
    face = entities.add_face [
      [0,             -face_depth, 0],
      [carcass_width, -face_depth, 0],
      [carcass_width, -face_depth, carcass_height],
      [0,             -face_depth, carcass_height],
    ]
    face.reverse! unless face.normal.samedirection?(Y_AXIS)
    face.pushpull face_depth

    face = entities.add_face [
      [face_border_width,                 -face_depth, face_border_width],
      [carcass_width - face_border_width, -face_depth, face_border_width],
      [carcass_width - face_border_width, -face_depth, carcass_height - face_border_width],
      [face_border_width,                 -face_depth, carcass_height - face_border_width],
    ]

    face.reverse! unless face.normal.samedirection?(Y_AXIS.reverse)
    face.pushpull -face_inset_depth
  end

  def self.draw_simple_face(entities, carcass_width, carcass_height, face_depth)
    face = entities.add_face [
      [0,             -face_depth, 0],
      [carcass_width, -face_depth, 0],
      [carcass_width, -face_depth, carcass_height],
      [0,             -face_depth, carcass_height],
    ]
    face.reverse! unless face.normal.samedirection?(Y_AXIS)
    face.pushpull face_depth
  end
end

menu = UI.menu("Extensions")
menu.add_item("Add Shaker Cabinet...") { ShakerCabinets::add_shaker_cabinet }
