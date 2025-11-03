module ShakerCabinets
  def self.add_shaker_cabinet
    inputs = UI.inputbox(
      ['Style', 'Carcass Width', 'Carcass Height', 'Carcass Depth', 'Face Border Width', 'Face Depth', 'Face Inset Depth', 'Handle Type', 'Handle Location'],
      ['Shaker', 24.inch, 24.inch, 24.inch, 2.inch, 1.inch, (1.to_f / 2).inch, 'Pull', 'Center'],
      ['Shaker|Plain', '', '', '', '', '', '', 'None|Pull|Knob', 'Top Left|Top Center|Top Right|Left|Center|Right|Bottom Left|Bottom Center|Bottom Right']
    )

    return unless inputs

    style, carcass_width, carcass_height, carcass_depth, face_border_width, face_depth, face_inset_depth, handle_type, handle_location = inputs

    model = Sketchup.active_model
    model.start_operation('Draw Shaker Cabinet')
    cabinet = model.definitions.add('Shaker Cabinet')

    ShakerCabinets::draw_carcass cabinet.entities, carcass_width, carcass_height, carcass_depth
    case style
    when 'Shaker'
      ShakerCabinets::draw_shaker_face cabinet.entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth
    when 'Plain'
      ShakerCabinets::draw_simple_face cabinet.entities, carcass_width, carcass_height, face_depth
    end

    handle_point, handle_orientation = case handle_location
    when 'Top Left'
      [Geom::Point3d.new(face_border_width / 2, -face_depth, carcass_height - face_border_width), :vertical]
    when 'Top Center'
      [Geom::Point3d.new(carcass_width / 2, -face_depth, carcass_height - face_border_width / 2), :horizontal]
    when 'Top Right'
      [Geom::Point3d.new(carcass_width - face_border_width / 2, -face_depth, carcass_height - face_border_width), :vertical]
    when 'Left'
      [Geom::Point3d.new(face_border_width / 2, -face_depth, carcass_height / 2), :vertical]
    when 'Center'
      if style == 'Plain'
        [Geom::Point3d.new(carcass_width / 2, -face_depth, carcass_height / 2), :horizontal]
      else
        [Geom::Point3d.new(carcass_width / 2, -face_depth + face_inset_depth, carcass_height / 2), :horizontal]
      end
    when 'Right'
      [Geom::Point3d.new(carcass_width - face_border_width / 2, -face_depth, carcass_height / 2), :vertical]
    when 'Bottom Left'
      [Geom::Point3d.new(face_border_width / 2, -face_depth, face_border_width), :vertical]
    when 'Bottom Center'
      [Geom::Point3d.new(carcass_width / 2, -face_depth, face_border_width / 2), :horizontal]
    when 'Bottom Right'
      [Geom::Point3d.new(carcass_width - face_border_width / 2, -face_depth, face_border_width), :vertical]
    end

    case handle_type
    when 'None'
      # nothing
    when 'Knob'
      ShakerCabinets::draw_knob cabinet.entities, handle_point
    when 'Pull'
      ShakerCabinets::draw_pull cabinet.entities, handle_point, handle_orientation
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
