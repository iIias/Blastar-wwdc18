import PlaygroundSupport
import SpriteKit
import GameplayKit

/*:
 
 # Blastar (2018)
 ### by Ilias Ennmouri
 
 ## Introduction
 
 Hi there! My goal when coming up with this game was making whoever's playing it nostalgic.
 To make this game retro I knew I had to imitate an old style of 2d video games with todays far more advanced technologies like for example the SpriteKit framework.
 The process of making it was really fun even though I only had little time to realize it.
 
 
 ## How to play:
You are (said to be) this excellent pilot flying through space.
While staring into infinity you will unexpectedly encounter a ton of beachballs.
 
 Those so-called **beachballs of death** damage your ground which keeps you alive and can be seen as your health.
 The beachballs will stop at a random y position and spin around their own anchorpoint for a couple of seconds before they hit you or your ground with accelerated speed.
 The amount of healthpoints you loose is always 30hp. The rest hp of the beachball will by indicated by it's decreasing transparency. You have lasercanons attached to your spaceship with which you can weaken the beachballs. (Your lasercanons fire as soon as you end the current touch).
 You can drag your ship anywhere on the x-axis as long as you tap and hold it.
 
 Stay alive as long as you can.
 But they are called **beachballs of death**, which means death is inevitable,...\
 _or is it_?
 
 */

class MenuScene: SKScene {
    
    var space: SKEmitterNode!
    
    var blastarImage: SKSpriteNode!
    
    var startGameLabel: SKLabelNode!
    
    public var soundIsEnabled = true
    public var musicIsEnabled = true
    
    var toggleMusic: SKSpriteNode!
    var toggleSoundEffects: SKSpriteNode!
    
    var backgroundMusic = SKAudioNode()
    
    var FramesArray = [SKTexture]()
    
    override func didMove(to view: SKView) {

        space = SKEmitterNode(fileNamed: "Space.sks")!
        space.position = CGPoint(x: 0, y: 768 / 2)
        space.advanceSimulationTime(10)
        space.zPosition = -1

        self.addChild(space)
        
        backgroundMusic = SKAudioNode(fileNamed: "Soundtrack.mp3")

        if musicIsEnabled {
            self.addChild(backgroundMusic)
        } else {
            self.backgroundMusic.removeFromParent()
        }
        
        self.music = musicIsEnabled
        self.sound = soundIsEnabled
        
        startGameLabel = self.childNode(withName: "startGameLabel") as! SKLabelNode
        
        blastarImage = self.childNode(withName: "blastarImage") as! SKSpriteNode
        
        // Animate 'Blastar' frames
        for i in 0...40 {
            let frameName = "Frames/\(i).png"
            FramesArray.append(SKTexture(imageNamed: frameName))
        }
        
        blastarImage = SKSpriteNode(imageNamed: "Frames/0.png")
        blastarImage.position = CGPoint(x: 0, y: 240)
        blastarImage.size = CGSize(width: 445, height: 290)
        blastarImage.run(SKAction.repeatForever(SKAction.animate(with: FramesArray, timePerFrame: 0.06)))
        self.addChild(blastarImage)
        
        toggleMusic = self.childNode(withName: "toggleMusic") as! SKSpriteNode
        toggleMusic.size = CGSize(width: 64, height: 64)
        toggleMusic.texture = SKTexture(imageNamed: "Sound_Icons/music_on")
        
        toggleSoundEffects = self.childNode(withName: "toggleSoundEffects") as! SKSpriteNode
        toggleSoundEffects.size = CGSize(width: 64, height: 64)
        toggleSoundEffects.texture = SKTexture(imageNamed: "Sound_Icons/sound_on")
        
        
        
        let fontURL = Bundle.main.url(forResource: "Joystix_Font/joystix-monospace", withExtension: "ttf")
        CTFontManagerRegisterFontsForURL(fontURL! as CFURL, CTFontManagerScope.process, nil)
        startGameLabel.fontName = "Joystix"
        
        var FadeActionArray = [SKAction]()
        FadeActionArray.append(SKAction.fadeOut(withDuration: 1))
        FadeActionArray.append(SKAction.fadeIn(withDuration: 1))
        startGameLabel.run(SKAction.repeatForever(SKAction.sequence(FadeActionArray)))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let pos = touch.location(in: self)
            let node = self.atPoint(pos)
            
            if node == toggleMusic {
                // Disable background soundtrack
                if musicIsEnabled {
                    musicIsEnabled = false
                    GameScene.audioProperties.music = false
                    backgroundMusic.removeFromParent()
                    toggleMusic.texture = SKTexture(imageNamed: "Sound_Icons/music_off")
                } else {
                    musicIsEnabled = true
                    GameScene.audioProperties.music = true
                    self.addChild(backgroundMusic)
                    toggleMusic.texture = SKTexture(imageNamed: "Sound_Icons/music_on")
                }
            } else if node == toggleSoundEffects {
                // Disable sound effects
                if soundIsEnabled {
                    soundIsEnabled = false
                    GameScene.audioProperties.sound = false
                    toggleSoundEffects.texture = SKTexture(imageNamed: "Sound_Icons/sound_off")
                } else {
                    soundIsEnabled = true
                    GameScene.audioProperties.sound = true
                    toggleSoundEffects.texture = SKTexture(imageNamed: "Sound_Icons/sound_on")
                }
            } else {
                if soundIsEnabled {
                    startGameLabel.run(SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false))
                }
                let gameSceneTemp = GameScene(fileNamed: "GameScene")
                self.scene?.view?.presentScene(gameSceneTemp!, transition: SKTransition.fade(withDuration: 0.5))
            }
        }
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Initialize all nodes
    
    var soundIsEnabled = GameScene.audioProperties.sound!
    var musicIsEnabled = GameScene.audioProperties.music!
    
    var space = SKEmitterNode()

    var score: Int = 0
    var scoreLabel = SKLabelNode()
    
    var gameOver: Bool = false
    var gameOverLabel = SKLabelNode()
    
    var player  = SKSpriteNode()
    
    var backgroundMusic = SKAudioNode()
    
    var ground  = SKSpriteNode()
    var groundLabel = SKLabelNode()
    
    // Set ground healthpoints to make game more difficult or easier
    var groundHp: Int = 600
    
    var pauseButton = SKSpriteNode()
    var pauseLabel = SKLabelNode()
    
    var timer: Timer!
    
    
    var playerCategory:    UInt32 = 0x1 << 0 // 1d
    var beachballCategory: UInt32 = 0x1 << 1 // 2d
    var shotCategory:      UInt32 = 0x1 << 2 // 4d
    var borderCategory:    UInt32 = 0x1 << 3 // 8d
    var groundCategory:    UInt32 = 0x1 << 4 // 16d
    
    override func didMove(to view: SKView) {
        // Setup all nodes
        backgroundMusic = SKAudioNode(fileNamed: "Soundtrack.mp3")
        if musicIsEnabled {
            self.addChild(backgroundMusic)
        } else {
            self.backgroundMusic.removeFromParent()
        }
        
        space = SKEmitterNode(fileNamed: "Space.sks")!
        space.position = CGPoint(x: 0, y: 768 / 2)
        space.advanceSimulationTime(10)
        space.zPosition = -1
        
        self.addChild(space)
        
        pauseButton = self.childNode(withName: "pauseButton") as! SKSpriteNode
        if pauseButton.texture == nil || pauseButton.texture == SKTexture(imageNamed: "Play_Pause/play.png") {
            pauseButton.texture = SKTexture(imageNamed: "Play_Pause/pause.png")
        }
        pauseButton.zPosition = 1
        
        let fontURL = Bundle.main.url(forResource: "Joystix_Font/joystix-monospace", withExtension: "ttf")
        CTFontManagerRegisterFontsForURL(fontURL! as CFURL, CTFontManagerScope.process, nil)
        pauseLabel = self.childNode(withName: "pauseLabel") as! SKLabelNode
        pauseLabel.isHidden = true
        pauseLabel.fontName = "Joystix"
        pauseLabel.text = "Game is paused"
        pauseLabel.fontSize = 24
        pauseLabel.zPosition = 1
        
        player = self.childNode(withName: "player") as! SKSpriteNode
        player.name = "Player"
        player.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        player.physicsBody = SKPhysicsBody()
        player.physicsBody?.affectedByGravity = false
        
        player.physicsBody?.isDynamic = true
        
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = beachballCategory
        
        ground = self.childNode(withName: "ground") as! SKSpriteNode
        ground.name = "Ground"
        ground.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        
        ground.physicsBody?.categoryBitMask = groundCategory
        ground.physicsBody?.contactTestBitMask = beachballCategory
        
        groundLabel = ground.childNode(withName: "groundLabel") as! SKLabelNode
        
        groundLabel.fontName = "Joystix"
        groundLabel.text = "\(groundHp)/600 HP"
        
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        scoreLabel.fontName = "Joystix"
        scoreLabel.fontSize = 24
        scoreLabel.text = "Score: \(score)"
        
        gameOverLabel = self.childNode(withName: "gameOverLabel") as! SKLabelNode
        gameOverLabel.isHidden = true
        gameOverLabel.fontName = "Joystix"
        gameOverLabel.fontSize = 48
        
        // Add Beachball every 1.5 seconds
        timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(addBeachball), userInfo: nil, repeats: true)
        
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.friction = 0
        border.restitution = 0
        self.physicsBody = border
        self.physicsBody?.categoryBitMask = borderCategory
        
        self.physicsWorld.contactDelegate = self
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody = SKPhysicsBody()
        var secondBody = SKPhysicsBody()
        
        if contact.bodyA.node?.name == "Shot" && contact.bodyB.node?.name == "Beachball" {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else if contact.bodyA.node?.name == "Beachball" && contact.bodyB.node?.name == "Shot"{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        } else if contact.bodyA.node?.name == "Beachball" && contact.bodyB.node?.name == "Ground" {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.node?.name == "Shot" && secondBody.node?.name == "Beachball" {

            if (secondBody.node?.hp)! > 10 {
                if soundIsEnabled {
                    secondBody.node?.run(SKAction.playSoundFileNamed("quietHit.wav", waitForCompletion: false))
                }
                secondBody.node?.alpha -= 1/3
                secondBody.node?.hp! -= 10
                score += 1
                
            } else if (secondBody.node?.hp)! <= 10 {
                if soundIsEnabled {
                    secondBody.node?.run(SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false))
                }
                secondBody.node?.hp! -= 10
                secondBody.node?.removeFromParent()
                score += 5
            }
            
            scoreLabel.text = "Score: \(score)"
            print(secondBody.node?.hp)
            firstBody.node?.removeFromParent()
            
        } else if firstBody.node?.name == "Beachball" && secondBody.node?.name == "Ground" {
            if soundIsEnabled {
                secondBody.node?.run(SKAction.playSoundFileNamed("groundHit.wav", waitForCompletion: false))
            }
            firstBody.node?.removeFromParent()
            if gameOver == false {
                groundHp -= 30
                if soundIsEnabled {
                    ground.run(SKAction.playSoundFileNamed("Explosion.wav", waitForCompletion: false))
                }
            }
            groundLabel.text = "\(groundHp)/600 HP"
            
            if groundHp >= 400 {
                ground.color = UIColor(red: 50.0/255.0, green: 205.0/255.0, blue: 50.0/255.0, alpha: 1)
            } else if groundHp < 400 && groundHp >= 400{
                ground.color = .orange
            } else if groundHp < 200 {
                ground.color = .red
            }
            
            if groundHp <= 0 {
                gameOver = true
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let pos = touch.location(in: self)
            let node = self.atPoint(pos)
            
            // Executed when pause button pressed
            if node == pauseButton {
                if gameOver == false {
                    if self.scene?.isPaused == true {
                        if soundIsEnabled {
                            pauseButton.run(SKAction.playSoundFileNamed("pause.wav", waitForCompletion: true))
                        }
                        pauseButton.texture = SKTexture(imageNamed: "Play_Pause/pause.png")
                        self.scene?.isPaused = false
                        for node in self.children as [SKNode] {
                            node.isPaused = false
                        }
                        pauseLabel.isHidden = true
                    } else {
                        if soundIsEnabled {
                            pauseButton.run(SKAction.playSoundFileNamed("pause.wav", waitForCompletion: true))
                        }
                        pauseButton.texture = SKTexture(imageNamed: "Play_Pause/play.png")
                        self.scene?.isPaused = true
                        for node in self.children as [SKNode] {
                            node.isPaused = true
                        }
                        pauseLabel.isHidden = false
                    }
                }
            }
        }
            
        for touch in touches {
            let location = touch.location(in: self)
            
            // Allow 'player' do be dragged on x-axis
            player.run(SKAction.moveTo(x: location.x, duration: 0.2))
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Touches ended
        shootLasergun()
    }
    
    @objc func addBeachball() {
        if self.scene?.isPaused == false {
            let beachball = SKSpriteNode(imageNamed: "beachball")
        // Make two different sizes of beachballs
        let random: Int = Int(arc4random_uniform(2)+2)
        beachball.size = CGSize(width: 128/Int(random), height: 128/Int(random))
        beachball.name = "Beachball"
            
        // Change healthpoints/strength of beachball to make game more difficult or easier
        beachball.hp = 30
        
        // Randomize beachballs x-axis value
        let randomPosition = GKRandomDistribution(lowestValue: -200, highestValue:200)
        let position = CGFloat(randomPosition.nextInt())
        
        // Setup beachball
        beachball.position = CGPoint(x: position, y: self.frame.size.height+beachball.size.height)
        beachball.physicsBody = SKPhysicsBody(circleOfRadius: beachball.size.height / 3)
        beachball.physicsBody?.isDynamic = true
        beachball.physicsBody?.affectedByGravity = false
        beachball.physicsBody?.categoryBitMask = beachballCategory
        beachball.physicsBody?.contactTestBitMask = shotCategory
        beachball.physicsBody?.collisionBitMask = 0
        
        self.addChild(beachball)
        
        let duration: TimeInterval = 5
        
        var actionArray = [SKAction]()
        
        // Randomize beachballs y-axis value
        let randomHeight = GKRandomDistribution(lowestValue: 0, highestValue:350)
        let height = CGFloat(randomHeight.nextInt())
            
        
        // Make beachball spin and expand when arrived at previous point
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: height), duration: duration))
        actionArray.append(SKAction.stop())
        
        let rotate = SKAction.rotate(byAngle: -CGFloat.pi*2, duration:  0.4)
        var rotationExpansionArray = [SKAction]()
        rotationExpansionArray.append(SKAction.resize(toWidth: 80, height: 80, duration: 3))
        rotationExpansionArray.append(SKAction.repeat(rotate, count: 12))
        
        actionArray.append(SKAction.group(rotationExpansionArray))
            
        actionArray.append(SKAction.stop())
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: self.ground.position.y), duration: 0.5))
        actionArray.append(SKAction.removeFromParent())
        
        beachball.run(SKAction.sequence(actionArray))
        }
    }
    
    func shootLasergun() {
        // Create laser node
        let shot = SKSpriteNode(color: .green, size: CGSize(width: 7, height: 7))
        // Call fire
        shot.name = "Shot"
        shot.position = player.position
        shot.position.y += 25
        shot.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 7, height: 7))
        shot.physicsBody?.friction = 0
        shot.physicsBody?.restitution = 0
        shot.physicsBody?.affectedByGravity = false
        shot.physicsBody?.collisionBitMask = beachballCategory
        shot.physicsBody?.categoryBitMask = shotCategory
        shot.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(shot)
        
        if soundIsEnabled {
            shot.run(SKAction.playSoundFileNamed("laserShot.wav", waitForCompletion: false))
        }
        shot.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 1))
    }

    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            player.run(SKAction.moveTo(x: location.x, duration: 0.1))
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if gameOver  {
            gameOverLabel.isHidden = false
                self.scene?.isPaused = true
                self.isPaused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // change 2 to desired number of seconds
                // Delayed code
                let menuSceneTemp = MenuScene(fileNamed: "MenuScene")
                self.scene?.view?.presentScene(menuSceneTemp!, transition: SKTransition.fade(withDuration: 0.5))
            }
        }
        
    }
}

extension SKNode {
    private struct entityProperties {
        static var hp: Int?
    }
    
    var hp: Int? {
        get { return entityProperties.hp }
        set { entityProperties.hp = newValue }
    }
}

extension SKScene {
    public struct audioProperties {
        static var music: Bool?
        static var sound: Bool?
    }
    
    var music: Bool? {
        get { return audioProperties.music }
        set { audioProperties.music = newValue }
    }
    
    var sound: Bool? {
        get { return audioProperties.sound }
        set { audioProperties.sound = newValue }
    }
}

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 445, height: 768))
if let scene = MenuScene(fileNamed: "MenuScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    
    // Present the scene
    sceneView.presentScene(scene)
}

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
