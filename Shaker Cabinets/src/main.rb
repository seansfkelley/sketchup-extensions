module ShakerCabinets
  def self.add_shaker_cabinet
    inputs = UI.inputbox(
      ['Type', 'Carcass Width', 'Carcass Height', 'Carcass Depth', 'Face Border Width', 'Face Depth', 'Face Inset Depth', 'Pull Type'],
      ['Cabinet (RH Pull)', 24.inch, 24.inch, 24.inch, 2.inch, 1.inch, (1.to_f / 2).inch, 'Knob'],
      ['Cabinet (Center Pull)|Cabinet (LH Pull)|Cabinet (RH Pull)|Drawer|Drawer (No Inset)', '', '', '', '', '', '', 'Knob|Pull|None']
    )

    return unless inputs

    cabinet_type, carcass_width, carcass_height, carcass_depth, face_border_width, face_depth, face_inset_depth, pull_type = inputs

    model = Sketchup.active_model
    model.start_operation("Draw Shaker #{cabinet_type}")
    cabinet = model.definitions.add("Shaker #{cabinet_type}")

    ShakerCabinets::draw_carcass cabinet.entities, carcass_width, carcass_height, carcass_depth
    case cabinet_type
    when 'Cabinet (Center Pull)', 'Cabinet (LH Pull)', 'Cabinet (RH Pull)', 'Drawer'
      ShakerCabinets::draw_shaker_face cabinet.entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth
    when 'Drawer (No Inset)'
      ShakerCabinets::draw_simple_face cabinet.entities, carcass_width, carcass_height, face_depth
    end

    pull_point, pull_orientation = case cabinet_type
    when 'Cabinet (Center Pull)'
      [Geom::Point3d.new(carcass_width / 2,                     -face_depth,                    carcass_height - face_border_width / 2), :horizontal]
    when 'Cabinet (LH Pull)'
      [Geom::Point3d.new(face_border_width / 2,                 -face_depth,                    carcass_height - face_border_width), :vertical]
    when 'Cabinet (RH Pull)'
      [Geom::Point3d.new(carcass_width - face_border_width / 2, -face_depth,                    carcass_height - face_border_width), :vertical]
    when 'Drawer'
      [Geom::Point3d.new(carcass_width / 2,                     -face_depth + face_inset_depth, carcass_height / 2), :horizontal]
    when 'Drawer (No Inset)'
      [Geom::Point3d.new(carcass_width / 2,                     -face_depth,                    carcass_height / 2), :horizontal]
    end

    case pull_type
    when 'None'
      # nothing
    when 'Knob'
      ShakerCabinets::draw_knob cabinet.entities, pull_point
    when 'Pull'
      ShakerCabinets::draw_pull cabinet.entities, pull_point, pull_orientation
    end

    model.active_entities.add_instance cabinet, ORIGIN

    model.commit_operation
  end

  def self.draw_carcass(entities, width, height, depth)
    face = entities.add_face [
      [0,     0, 0],
      [width, 0, 0],
      [width, 0, height],
      [0,     0, height],
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

  def self.draw_knob(entities, point)
    circle = entities.add_circle point, Y_AXIS.reverse, (1.to_f / 2).inch
    circle[0].find_faces # actually create the circle face
    face = circle[0].faces.first
    face.pushpull 1.inch
  end

  def self.draw_pull(entities, point, orientation)

  end
end

menu = UI.menu("Extensions")
menu.add_item("Add Shaker Cabinet...") { ShakerCabinets::add_shaker_cabinet }
