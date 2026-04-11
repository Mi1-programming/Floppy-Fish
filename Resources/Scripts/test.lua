local playerConfig = {
    jumpPower = 25.0,
    velocityLoss = 20.0,
    gravity = 15.0,
    velocityRotateAnimation = 120.0
}
local pipeConfig = {
    gap = 10,
    speed = 3,
    xLoopBounds = 8,
    yRandomness = 2
}
local mapConfig = {
    yBounds = 5,
    backgroundWidth = 20.0,
    backgroundHeight = 10.0
}
local lastTime = 0.0

function MakeBoxCollider(parent, offsetX, offsetY, width, height)
    local collider = {
        parent = parent,
        offsetX = offsetX,
        offsetY = offsetY,
        width = width,
        height = height,
    }
    return collider
end
function HandleCollision(colliderA, colliderB)

    local colliderAPosition = colliderA.parent.position:get()
    local colliderBPosition = colliderB.parent.position:get()

    local distanceX = (colliderA.width + colliderB.width) * 0.5
    local distanceY = (colliderA.height + colliderB.height) * 0.5

    local colliderAOffsetPositionX = colliderAPosition.x + colliderA.offsetX
    local colliderAOffsetPositionY = colliderAPosition.y + colliderA.offsetY

    local colliderBOffsetPositionX = colliderBPosition.x + colliderB.offsetX
    local colliderBOffsetPositionY = colliderBPosition.y + colliderB.offsetY

    local xHit =
        colliderAOffsetPositionX + distanceX > colliderBOffsetPositionX and
        colliderAOffsetPositionX - distanceX < colliderBOffsetPositionX
    local yHit =
        colliderAOffsetPositionY + distanceY > colliderBOffsetPositionY and
        colliderAOffsetPositionY - distanceY < colliderBOffsetPositionY

    local hit = xHit and yHit
    return hit
end
function BuildBackground(name, texture)
    Scene:addObject(name)
    local background = Scene:getObject(name)

    background:addComponent("TransformComponent")
    local backgroundTransform = background:getComponent("TransformComponent")
    backgroundTransform.position:set(0, 0, 4)
    backgroundTransform.scale:set(mapConfig.backgroundWidth, mapConfig.backgroundHeight, 1)

    background:addComponent("RenderComponent")
    local backgroundRenderer = background:getComponent("RenderComponent")
    backgroundRenderer:setShader("default")
    backgroundRenderer:setTexture(texture)

    local build = {
        gameObject = background,
        transform = backgroundTransform,
        renderer = backgroundRenderer
    }
    return build
end
function BuildParallaxBackground(name, texture)
    local backgroundA = BuildBackground(name .. "_1", texture)
    local backgroundB = BuildBackground(name .. "_2", texture)

    local build = {
        backgroundA = backgroundA,
        backgroundB = backgroundB,
        xMoved = 0
    }
    return build
end
function UpdateParallaxBackground(parallaxBackground, deltaTime, scrollSpeed)
    parallaxBackground.xMoved = (parallaxBackground.xMoved + scrollSpeed * deltaTime) % 1.0
    parallaxBackground.backgroundA.transform.position:setX(-parallaxBackground.xMoved * mapConfig.backgroundWidth)
    parallaxBackground.backgroundB.transform.position:setX((-parallaxBackground.xMoved + 1) * mapConfig.backgroundWidth)
end
function MakePlayer()
    Scene:addObject("Flappyfish")
    local flappyBird = Scene:getObject("Flappyfish")

    flappyBird:addComponent("TransformComponent")
    local flappyBirdTransform = flappyBird:getComponent("TransformComponent")

    flappyBird:addComponent("RenderComponent")
    local flappyBirdRenderer = flappyBird:getComponent("RenderComponent")
    flappyBirdRenderer:setShader("default")
    flappyBirdRenderer:setTexture("fish")

    local player = {
        gameObject = flappyBird,
        transform = flappyBirdTransform,
        renderer = flappyBirdRenderer,
        yPosition = 0.0,
        lastYPosition = 0.0,
        yVelocity = playerConfig.jumpPower,
        collider = MakeBoxCollider(flappyBirdTransform, 0.0, 0.0, 0.35, 0.35)
    }
    return player
end
function UpdatePlayer(player, deltaTime)
    if Input:keyPressed("W") then
		player.yVelocity = playerConfig.jumpPower
	end

    player.yPosition =
        player.yPosition -
        playerConfig.gravity * deltaTime +
        player.yVelocity * deltaTime

    player.yVelocity = math.max(player.yVelocity - playerConfig.velocityLoss * deltaTime, 0.0)

    local playerDeltaY = player.yPosition - player.lastYPosition

    player.transform.position:setY(player.yPosition)
    player.transform.rotation:setZ(playerDeltaY * -playerConfig.velocityRotateAnimation)

    player.lastYPosition = player.yPosition
end
function BuildPipe(name)
    Scene:addObject(name)
    local pipe = Scene:getObject(name)

    pipe:addComponent("TransformComponent")
    local pipeTransform = pipe:getComponent("TransformComponent")
    pipeTransform.scale:setY(8.0)

    pipe:addComponent("RenderComponent")
    local pipeRenderer = pipe:getComponent("RenderComponent")
    pipeRenderer:setShader("default")
    pipeRenderer:setTexture("pipe")

    local builtPipe = {
        gameObject = pipe,
        transform = pipeTransform,
        renderer = pipeRenderer,
        collider = MakeBoxCollider(pipeTransform, 0.0, 0.0, 1.0, 8.0)
    }

    return builtPipe
end
function BuildPipeColumn()

    local bottomPipe = BuildPipe("BottomPipe")

    local topPipe = BuildPipe("TopPipe")
    topPipe.transform.rotation:setZ(180)

    local pipeColumn = {
        bottomPipe = bottomPipe,
        topPipe = topPipe,
        positionX = -pipeConfig.xLoopBounds,
        positionY = 0
    }
    return pipeColumn
end
function UpdatePipeColumn(pipeColumn, deltaTime)
    pipeColumn.positionX = pipeColumn.positionX + pipeConfig.speed * deltaTime
    if pipeColumn.positionX > pipeConfig.xLoopBounds then
        pipeColumn.positionX = -pipeConfig.xLoopBounds
        pipeColumn.positionY = (math.random() - 0.5) * 2.0 * pipeConfig.yRandomness
    end

    -- Update the transforms

    local gapCenter = pipeConfig.gap * 0.5

    pipeColumn.bottomPipe.transform.position:set(pipeColumn.positionX, pipeColumn.positionY + gapCenter, 0)
    pipeColumn.topPipe.transform.position:set(pipeColumn.positionX, pipeColumn.positionY - gapCenter, 0)
end
function PlayerHandlePipeColumnCollisions(player, pipeColumn)
    local topPipeCollision = HandleCollision(player.collider, pipeColumn.topPipe.collider)
    local bottomPipeCollision = HandleCollision(player.collider, pipeColumn.bottomPipe.collider)
    local hasCollision = topPipeCollision or bottomPipeCollision
    return hasCollision
end
function ResetPlayer(player)
    player.yPosition = 0.0
    player.yVelocity = playerConfig.jumpPower
end
function ResetPipeColumn(pipeColumn)
    pipeColumn.positionX = -pipeConfig.xLoopBounds
    pipeColumn.positionY = 0
end
function PlayerIsOutOfBounds(player)
    local isOverMap = player.yPosition > mapConfig.yBounds
    local isBelowMap = player.yPosition < -mapConfig.yBounds
    local isOutOfBounds = isOverMap or isBelowMap
    return isOutOfBounds
end

local background = BuildParallaxBackground("Background_Layer_1", "background_layer_1")
local player = MakePlayer()
local pipeColumn = BuildPipeColumn()

function update(time)
    local deltaTime = time - lastTime

    UpdateParallaxBackground(background, deltaTime, 0.1)
    UpdatePlayer(player, deltaTime)
    UpdatePipeColumn(pipeColumn, deltaTime)
    
    local hadCollision = PlayerHandlePipeColumnCollisions(player, pipeColumn)
    local isOutOfBounds = PlayerIsOutOfBounds(player)
    local hasLost = hadCollision or isOutOfBounds
    if hasLost then
        ResetPlayer(player)
        ResetPipeColumn(pipeColumn)
        print("Lose!")
        
    end
    if Input:keyPressed("R") then
        ResetPlayer(player)
        ResetPipeColumn(pipeColumn)
        return
    end

    lastTime = time
end