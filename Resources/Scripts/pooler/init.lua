local pooler = {}

function pooler.Spawn(pool)
    local freeInstance = nil
    for _, instance in pairs(pool.freeInstances) do
        freeInstance = instance
        break
    end

    if freeInstance == nil then return end
    
    pool.freeInstances[freeInstance.index] = nil
    pool.usedInstances[freeInstance.index] = freeInstance
    pool.spawnFunction(freeInstance)

    return freeInstance
end
function pooler.Destroy(instance)
    local pool = instance.pool
    pool.usedInstances[instance.index] = nil
    pool.freeInstances[instance.index] = instance
    pool.destroyFunction(instance)
end
function pooler.Clear(pool)
    local instances = {table.unpack(pool.usedInstances)}
    for _, instance in pairs(instances) do
        pooler.Destroy(instance)
    end
end
function pooler.Create(makeFunction, count, spawnFunction, destroyFunction)
    local pool = {
        usedInstances = {},
        freeInstances = {},
        spawnFunction = spawnFunction,
        destroyFunction = destroyFunction
    }
    for i = 1, count do
        local newInstance = {
            index = i,
            object = makeFunction(i),
            pool = pool
        }
        pool.destroyFunction(newInstance)
        table.insert(pool.freeInstances, i, newInstance)
        pool.freeInstances[i] = newInstance
    end
    return pool
end

return pooler