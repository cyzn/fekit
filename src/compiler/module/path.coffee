syspath = require 'path'
utils = require '../../util'

### ---------------------------
    模块路径
###
class ModulePath

    # @uri 物理真实路径
    constructor:( @uri ) ->

    parseify:( path_without_extname ) ->
        extname = @extname()
        if ~ModulePath.EXTLIST.indexOf( extname )
            result = utils.file.findify( path_without_extname , ModulePath.EXTLIST )
            #如果仍然没有，则以 path_without_extname 为目录名进行测试
            if result is null and utils.path.is_directory( path_without_extname )
                p = utils.path.join( path_without_extname , "index" )
                result = utils.file.findify( p , ModulePath.EXTLIST )
        if result
            console.info("result>>",result)
            return result
        else
            throw "找不到文件或对应的编译方案 [#{path_without_extname}] 后缀检查列表为[#{ModulePath.EXTLIST}]"

    extname:() ->
        return syspath.extname(@uri)

    dirname:() ->
        return syspath.dirname(@uri)

    getFullPath:()->
        return @uri

    getContentType:()->
        return ModulePath.getContentType( @extname() )

###
    解析子模块真实路径

    子模块路径表现形式可以是
        省略后缀名方式, 该方式会认为子模块后缀名默认与parentModule相同
            a/b/c
            a.b.c
            
            后缀名默认匹配顺序为, 如果都找不到就会报错
            [javascript]
            .js / .coffee / .mustache 
            [css]
            .css / .less

    子模块的

    子模块路径分2种
    1, 相对路径, 相对于父模块的dirname. 如 a/b/c
    2, 库引用路径, 库是由配置指定的路径. 如 core/a/b/c , core是在配置文件中进行配置的

###
ModulePath.resolvePath = ( path , parentModule ) ->
    parts = utils.path.split_path( path , ModulePath.EXTLIST )
    result = []

    # 解析全路径
    for part , i in parts
        if i == 0
            package_path = parentModule.config.getPackage( part ) 
            if package_path
                result.push( package_path )
            else if parentModule.config.isUseLibrary( part )
                # 库引用路径
                result.push( parentModule.config.parseLibrary( part ) )    
            else
                # 相对路径
                result.push( parentModule.path.dirname() )
                result.push( part )
        else
            result.push( part )

    if parts.length is 1 and !package_path and !parentModule.config.isUseLibrary( part )
        throw "[COMPILE] 引用模块出错! 找不到 #{parts.join('')} 在 #{parentModule.path.uri} 中"


    # 解析文件名( 猜文件名 )
    path_without_extname = syspath.join.apply( syspath , result )
    truelypath = parentModule.path.parseify( path_without_extname )
    utils.logger.trace("[COMPILE] 解析子模块真实路径 #{path} >>>> #{truelypath}")
    return truelypath

ModulePath.getContentType = ( extname ) ->
    ModulePath.EXTTABLE[ extname ]?.contentType


ModulePath.addExtensionPlugin = ( extName , plugin ) ->
    ModulePath.EXTLIST.push( extName )
    ModulePath.EXTTABLE[ extName ] = plugin

ModulePath.getPlugin = ( extName ) ->
    ModulePath.EXTTABLE[ extName ]

# 后缀列表 
ModulePath.EXTLIST = []
ModulePath.EXTTABLE = {}


exports.ModulePath = ModulePath