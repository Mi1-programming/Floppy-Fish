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
    yBounds = 5
}
local parallaxConfig = {
    backgroundWidth = 20.0,
    backgroundHeight = 10.0,
    backgrounds = {
        {
            name = "Background_layer_1",
            sprite = "background_layer_1",
            scrollSpeed = -0.0025,
            positionZ = 6
        },
        {
            name = "Background_layer_2",
            sprite = "background_layer_2",
            scrollSpeed = -0.05,
            positionZ = 5
        },
        {
            name = "Background_layer_3",
            sprite = "background_layer_3",
            scrollSpeed = -0.1,
            positionZ = 4
        },
        {
            name = "aaaaa", -- PLEASE DON'T CHANGE THIS. THINGS WILL BREAK IF IT SAYS ANYTHING ELSE
            sprite = "background_layer_4",
            scrollSpeed = -0.35,
            positionZ = 0
        }
    }
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
function BuildBackground(name, texture, positionZ)
    Scene:addObject(name)
    local background = Scene:getObject(name)

    background:addComponent("TransformComponent")
    local backgroundTransform = background:getComponent("TransformComponent")
    backgroundTransform.position:set(0, 0, positionZ)
    backgroundTransform.scale:set(parallaxConfig.backgroundWidth, parallaxConfig.backgroundHeight, 1)

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
function BuildParallaxBackground(name, texture, scrollSpeed, positionZ)
    local backgroundA = BuildBackground(name .. "_1", texture, positionZ)
    local backgroundB = BuildBackground(name .. "_2", texture, positionZ)

    local build = {
        backgroundA = backgroundA,
        backgroundB = backgroundB,
        scrollSpeed = scrollSpeed,
        xMoved = 0
    }
    return build
end
function BuildParallax(backgrounds)
    local builtBackgrounds = {}
    for _, value in pairs(backgrounds) do
        local builtBackground = BuildParallaxBackground(value.name, value.sprite, value.scrollSpeed, value.positionZ)
        table.insert(builtBackgrounds, builtBackground)
    end
    return builtBackgrounds
end
function ResetParallaxBackground(parallaxBackground)
    parallaxBackground.xMoved = 0.0
    parallaxBackground.backgroundA.transform.position:setX(0.0)
    parallaxBackground.backgroundB.transform.position:setX(parallaxConfig.backgroundWidth)
end
function UpdateParallaxBackground(parallaxBackground, deltaTime)
    parallaxBackground.xMoved = (parallaxBackground.xMoved + parallaxBackground.scrollSpeed * deltaTime) % 1.0
    parallaxBackground.backgroundA.transform.position:setX(-parallaxBackground.xMoved * parallaxConfig.backgroundWidth)
    parallaxBackground.backgroundB.transform.position:setX((-parallaxBackground.xMoved + 1) * parallaxConfig.backgroundWidth)
end
function UpdateParallax(backgrounds, deltaTime)
    for _, value in ipairs(backgrounds) do
        UpdateParallaxBackground(value, deltaTime)
    end
end
function MakePlayer()
    Scene:addObject("Player")
    local player = Scene:getObject("Player")

    player:addComponent("TransformComponent")
    local playerTransform = player:getComponent("TransformComponent")

    player:addComponent("RenderComponent")
    local playerRenderer = player:getComponent("RenderComponent")
    playerRenderer:setShader("default")
    playerRenderer:setTexture("fish")

    local player = {
        gameObject = player,
        transform = playerTransform,
        renderer = playerRenderer,
        yPosition = 0.0,
        lastYPosition = 0.0,
        yVelocity = playerConfig.jumpPower,
        collider = MakeBoxCollider(playerTransform, 0.0, 0.0, 0.35, 0.35)
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
function ResetParallax(backgrounds)
    for _, value in ipairs(backgrounds) do
        ResetParallaxBackground(value)
    end
end
function PlayerIsOutOfBounds(player)
    local isOverMap = player.yPosition > mapConfig.yBounds
    local isBelowMap = player.yPosition < -mapConfig.yBounds
    local isOutOfBounds = isOverMap or isBelowMap
    return isOutOfBounds
end

local player = MakePlayer()
local pipeColumn = BuildPipeColumn()
local parallax = BuildParallax(parallaxConfig.backgrounds)

function update(time)
    local deltaTime = time - lastTime

    UpdateParallax(parallax, deltaTime)
    UpdatePlayer(player, deltaTime)
    UpdatePipeColumn(pipeColumn, deltaTime)
    
    local hadCollision = PlayerHandlePipeColumnCollisions(player, pipeColumn)
    local isOutOfBounds = PlayerIsOutOfBounds(player)
    local hasLost = hadCollision or isOutOfBounds
    if hasLost then
        ResetPlayer(player)
        ResetPipeColumn(pipeColumn)
        ResetParallax(parallax)
        print("Lose!")
    end
    if Input:keyPressed("R") then
        ResetPlayer(player)
        ResetPipeColumn(pipeColumn)
        ResetParallax(parallax)
        return
    end

    lastTime = time
end