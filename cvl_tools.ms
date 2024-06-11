
global texture_path = ""

fn createMaterial materialName diffuseColor texture specValue matType =
(
	if matType == "Standard" then
	(
		material = StandardMaterial name:materialName
		material.diffuse = color diffuseColor[1] diffuseColor[2] diffuseColor[3]

		bitmaptext = Bitmaptexture filename:texture
		material.diffuseMap = bitmaptext
		material.Specular_Level = specValue
	)
	else if matType == "GTA Material" then
	(
		material = GTA_Mtl name:materialName
		bitmaptext = Bitmaptexture filename:texture
		material.colormap = bitmaptext
		material.spc = specValue/100.0
		material.color = color diffuseColor[1] diffuseColor[2] diffuseColor[3]
	)
    else
    (
        material = RW_Mtl name:materialName
		material.name = materialName
		bitmaptext = Bitmaptexture filename:texture
		material.texmap_texture = bitmaptext
		material.sp_specular = specValue/100.0
		material.color = color diffuseColor[1] diffuseColor[2] diffuseColor[3]
    )
	
	for obj in selection do
	(
		if isValidNode obj do
		(
			obj.material = material
		)
	)
	material
)


fn getAverageCoordinates coords =
(
    numCoords = coords.count
    add_x = 0
    add_y = 0
    add_z = 0
    for coord in coords do
    (
        add_x += coord.x
        add_y += coord.y
        add_z += coord.z
    )
    promedio_x = add_x / numCoords
    promedio_y = add_y / numCoords
    promedio_z = add_z / numCoords

    [promedio_x, promedio_y, promedio_z]
)

fn getAverageNormal normals =
(
    flatNormals = #()
    for nList in normals do
    (
        flatNormals += nList
    )

    numNormals = flatNormals.count
    add_x = 0
    add_y = 0
    add_z = 0
    for normal in flatNormals do
    (
        add_x += normal.x
        add_y += normal.y
        add_z += normal.z
    )
    promedio_x = add_x / numNormals
    promedio_y = add_y / numNormals
    promedio_z = add_z / numNormals

    normalize [promedio_x, promedio_y, promedio_z]
)

fn createDummyFromSelectedObject dummy_name meshType offset arrow =
(
    if dummy_name != "" do
    (
        local face_centers
        local face_normals

        if meshType == Editable_mesh then
        (
            faces = getFaceSelection $
            face_centers = for face in faces collect (meshop.getFaceCenter $ face)
            face_normals = for face in faces collect (meshop.getFaceRNormals $ face)
        )
        else if meshType == Editable_Poly then
        (
            faces = $.EditablePoly.GetSelection #face
            face_centers = for face in faces collect (polyOp.GetFaceCenter $ face)
            face_normals = for face in faces collect (polyOp.getFaceNormal $ face)
        )
        
        coords = getAverageCoordinates face_centers
        normal = getAverageNormal face_normals
		
        coords_with_offset = coords + (normal * offset)
		
		mdummy = Dummy()
		
		if arrow do
		(
			-- The arrow helper
			arrow_helper = ArrowHelper()
			arrow_helper.name = "arrow_helper_w"
			arrow_helper.rotation = EulerAngles 90 0 0
			arrow_helper.parent = mdummy
		)
		
        mdummy.position = coords_with_offset

		local origin = coords
		local target = coords + (normal * offset*3)

		--direction = normalize (origin - target) --inverted
		direction = normalize (target - origin)

		xAxis = normalize (cross direction [0,0,1])
		yAxis = direction
		zAxis = cross xAxis yAxis

		mdummy.transform = matrix3 xAxis yAxis zAxis mdummy.position

		-- Resize arrow and dummy
		mdummy.scale = [0.015, 0.015, 0.015]
		
		if arrow do
		(
			arrow_helper.scale = [0.015, 0.015, 0.015]
		)

        mdummy.name = dummy_name

        clearSelection()
        select mdummy
    )
)

fn selectDam =
(
    for obj in objects do
    (
        if (matchPattern obj.name pattern:"*_dam") or (matchPattern obj.name pattern:"*_vlo") do
        (
            selectMore obj
        )
    )
)

fn clearArrows =
(
	objectsToDelete = for obj in objects where obj.name == "arrow_helper_w" collect obj
    for obj in objectsToDelete do
    (
        delete obj
    )
)

fn showAlert title message =
(
    messageBox message title: title beep: false
)

global buttons1 = #(
    #("head_l", #(255, 175, 1, "")),	-- No dummy name = no create dummy
    #("head_r", #(1, 255, 200, "")),
    #("indicatorf_l", #(255, 174, 1, "indicatorsf")),
    #("indicatorf_r", #(1, 255, 199, "indicatorsf")),
    #("fogf_l", #(255, 173, 1, "foglightsf")),
    #("fogf_r", #(1, 255, 198, "foglightsf")),
    #("parkf_l", #(255, 171, 1, "parklightsf")),
    #("parkf_r", #(1, 255, 196, "parklightsf"))
)

global buttons2 = #(
    #("indicator_l", #(1, 195, 255, "indicators")),
    #("indicator_r", #(120, 1, 255, "indicators")),
    #("tail_l", #(185, 255, 1, "taillights")),
    #("tail_r", #(255, 60, 1, "taillights")),
    #("brake_l", #(184, 255, 1, "brakelights")),
    #("brake_r", #(255, 59, 1, "brakelights")),
    #("reverse_l", #(183, 255, 1, "reverselights")),
    #("reverse_r", #(255, 58, 1, "reverselights")),
    #("indicatorr_l", #(182, 255, 1, "indicatorsr")),
    #("indicatorr_r", #(255, 57, 1, "indicatorsr")),
    #("fogr_l", #(181, 255, 1, "foglightsr")),
    #("fogr_r", #(255, 56, 1, "foglightsr"))
)

global buttons = buttons1 + buttons2

fn findButton button_name = (
    for i = 1 to buttons.count do (
        if buttons[i][1] == button_name do (
            return buttons[i]
        )
    )
    undefined
)

try(destroyDialog toolsRollout) catch()
rollout toolsRollout "CVehLights Tools v1.32 by Weaita"
(
    group "Front" (
        -- buttons1
        button head_l_btn "head_l" across:2 align:#left
        button head_r_btn "head_r" across:2 align:#left
        button indicatorf_l_btn "indicatorf_l" across:2 align:#left
        button indicatorf_r_btn "indicatorf_r" across:2 align:#left
        button fogf_l_btn "fogf_l" across:2 align:#left
        button fogf_r_btn "fogf_r" across:2 align:#left
        button parkf_l_btn "parkf_l" across:2 align:#left
        button parkf_r_btn "parkf_r" across:2 align:#left
    )
    group "Rear / Others" (
        -- buttons2
        button indicator_l_btn "indicator_l" across:2 align:#left
        button indicator_r_btn "indicator_r" across:2 align:#left
        button tail_l_btn "tail_l" across:2 align:#left
        button tail_r_btn "tail_r" across:2 align:#left
        button brake_l_btn "brake_l" across:2 align:#left
        button brake_r_btn "brake_r" across:2 align:#left
        button reverse_l_btn "reverse_l" across:2 align:#left
        button reverse_r_btn "reverse_r" across:2 align:#left
        button indicatorr_l_btn "indicatorr_l" across:2 align:#left
        button indicatorr_r_btn "indicatorr_r" across:2 align:#left
        button fogr_l_btn "fogr_l" across:2 align:#left
        button fogr_r_btn "fogr_r" across:2 align:#left
    )
	
	group "Config" (
		button selectTexture "Select texture" across:2 align:#left
		label separator1 ""
		edittext specLevel "Spec Level:" text:"100" across:2 align:#left
		edittext offsetValue " DOffset:" text:"0.02" across:2 align:#left toolTip:"The distance between the face and Dummy"
		dropdownlist materialType "Material Type:" items:#("Standard", "GTA Material", "RW Material") selection:1 across:2 align:#left
		
		label separator2 ""
		checkbox cbArrows "Arrows helpers" checked:false toolTip:"Create Arrow Helpers inside Dummy \nWarning: Don't forget to delete them before exporting the vehicle (use Delete arrows)"
		checkbox cbDummy "Dummy" checked:true toolTip:"Create dummy"
	)
	
	group "Tools" (
		button selectDamVlo "Select dam/vlo" across:2 align:#left toolTip:"Select all _damn and _vlo objects"
		button cArrows "Delete arrows" across:2 align:#left toolTip:"Delete all the help arrows from the scene, you should always do this before exporting the vehicle"
		button showInfo "Info" across:2 align:#left
	)
	
	fn buttonClicked buttonName =
	(
		if selection.count > 0 then
		(
			buttonData = findButton buttonName
			if buttonData != undefined do
			(
				diffuseColor = buttonData[2]
				dummyName = buttonData[2][4]
				
				materialName = buttonName
				texture = texture_path

				if texture != "" then
				(
					specValue = specLevel.text as integer
					matType = materialType.selected
					offset = offsetValue.text as float
					arrow = cbArrows.checked
					cDummy = cbDummy.checked
					
					meshType = classof selection[1]
					selectedFaceCount = 0
					
					-- editable poly
					if meshType == Editable_Poly then
					(
						sel_faces = $.EditablePoly.GetSelection #face
						local selectedFaceCount = 0
						for face in sel_faces do
						(
							if face != 0 then
							(
								selectedFaceCount += 1
							)
						)
					)
					-- editable mesh
					else if meshType == Editable_mesh then
					(
						sel_faces = getFaceSelection $
						local selectedFaceCount = 0
						for face in sel_faces do
						(
							if face != 0 then
							(
								selectedFaceCount += 1
							)
						)
					)
					else
					(
						showAlert "Error" "Select an editable mesh or editable Poly"
					)
				
					if selectedFaceCount > 0 then
					(
						createMaterial materialName diffuseColor texture specValue matType
						if cDummy do
						(
							createDummyFromSelectedObject dummyName meshType offset arrow
						)
					)
					else
					(
						showAlert "Error" "Select faces"
					)
				)
				else
				(
					showAlert "Error" "Please select a texture"
					print "ERROR: No texture"
				)
			)
		)
		else
		(
			showAlert "Error" "Select an object"
		)
	)
	
    on head_l_btn pressed do buttonClicked "head_l"
    on head_r_btn pressed do buttonClicked "head_r"
    on indicatorf_l_btn pressed do buttonClicked "indicatorf_l"
    on indicatorf_r_btn pressed do buttonClicked "indicatorf_r"
    on fogf_l_btn pressed do buttonClicked "fogf_l"
    on fogf_r_btn pressed do buttonClicked "fogf_r"
    on parkf_l_btn pressed do buttonClicked "parkf_l"
    on parkf_r_btn pressed do buttonClicked "parkf_r"
    on indicator_l_btn pressed do buttonClicked "indicator_l"
    on indicator_r_btn pressed do buttonClicked "indicator_r"
    on tail_l_btn pressed do buttonClicked "tail_l"
    on tail_r_btn pressed do buttonClicked "tail_r"
    on brake_l_btn pressed do buttonClicked "brake_l"
    on brake_r_btn pressed do buttonClicked "brake_r"
    on reverse_l_btn pressed do buttonClicked "reverse_l"
    on reverse_r_btn pressed do buttonClicked "reverse_r"
    on indicatorr_l_btn pressed do buttonClicked "indicatorr_l"
    on indicatorr_r_btn pressed do buttonClicked "indicatorr_r"
    on fogr_l_btn pressed do buttonClicked "fogr_l"
    on fogr_r_btn pressed do buttonClicked "fogr_r"
		
    on selectDamVlo pressed do
    (
        selectDam()
    )
	
	on cArrows pressed do
    (
        clearArrows()
    )

    on selectTexture pressed do
    (
        texture_path = getOpenFileName types:"Images (*.png;*.jpg;*.tga;*.dds;*.jpeg)|*.png;*.jpg;*.tga;*.dds;*.jpeg"
        if texture_path != undefined do
        (
            selectTexture.text = getFilenameFile texture_path
            print ("Loaded image: " + texture_path)
        )
    )

    on showInfo pressed do
    (
        showAlert "Info" "Script made by Weaita\n \n If you want to change the names of the buttons, the generated dummies or the assigned colors, then edit the buttons1 and buttons2 arrays in the .ms file"
    )
)

createDialog toolsRollout width:250 height:550
