local Players = game:GetService('Players')
local RunService = game:GetService("RunService")
local AssetService = game:GetService('AssetService')

local RADIUS = 25
local ORIGIN_REFERENCE: Part | Attachment = Players.LocalPlayer.Character.HumanoidRootPart
local SUBJECT_REFERENCE: MeshPart = workspace:WaitForChild("building")

local vertexCache = {}
local faceTable = {}

local em = AssetService:CreateEditableMeshAsync(Content.fromUri(SUBJECT_REFERENCE.MeshId), {
	FixedSize = false
})
em:RemoveUnused()
local actualEm = AssetService:CreateEditableMesh()

RunService.RenderStepped:Connect(function(_)
	local origin = ORIGIN_REFERENCE.Position

	for _, face in em:GetFaces() do
		local faceVertices = em:GetFaceVertices(face)

		local faceInRadius = true
		for _, vertex in faceVertices do
			local posi = em:GetPosition(vertex)
			
			local worldSpace = SUBJECT_REFERENCE.Position + Vector3.new(posi.X*-1, posi.Y, posi.Z*-1)
			if (origin - worldSpace).Magnitude > RADIUS then
				faceInRadius = false
				break
			end
		end

		local actualFace = faceTable[face]
		if not faceInRadius and actualFace then
			local oldVertices = actualEm:GetFaceVertices(actualFace)
			actualEm:RemoveFace(actualFace)

			faceTable[face] = nil
			vertexCache[face] = oldVertices

		elseif faceInRadius and not actualFace then
			local av1, av2, av3 = vertexCache[face][1], vertexCache[face][2], vertexCache[face][3]
			faceTable[face] = actualEm:AddTriangle(av1, av2, av3)
		end
	end
end)

for _, face in em:GetFaces() do -- copy base EditableMesh to Actual EditableMesh
	local faceVertices = em:GetFaceVertices(face)
	local v0, v1, v2 = em:GetPosition(faceVertices[1]), em:GetPosition(faceVertices[2]), em:GetPosition(faceVertices[3])
	av1, av2, av3 = actualEm:AddVertex(v0), actualEm:AddVertex(v1), actualEm:AddVertex(v2)
	faceTable[face] = actualEm:AddTriangle(av1, av2, av3)
	
	vertexCache[face] = {av1, av2, av3}
end

local meshpart = AssetService:CreateMeshPartAsync(Content.fromObject(actualEm)) -- set mesh reference to the Actual EditableMesh
SUBJECT_REFERENCE:ApplyMesh(meshpart)
