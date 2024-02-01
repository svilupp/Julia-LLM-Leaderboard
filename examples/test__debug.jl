using Test

# FILEPATH: /root/Julia-LLM-Leaderboard/examples/_debug_test.jl

# Test detect_base_main_overrides function
@testset "detect_base_main_overrides" begin
    # Test case 1: No overrides detected
    code_block_1 = """
    function foo()
        println("Hello, World!")
    end
    """
    @test detect_base_main_overrides(code_block_1) == (false, [])

    # Test case 2: Overrides detected
    code_block_2 = """
    function Base.bar()
        println("Override Base.bar()")
    end

    function Main.baz()
        println("Override Main.baz()")
    end
    """
    @test detect_base_main_overrides(code_block_2) == (true, ["Base.bar", "Main.baz"])

    # Test case 3: Overrides with base imports
    code_block_3 = """
    using Base: sin

    function Main.qux()
        println("Override Main.qux()")
    end
    """
    @test detect_base_main_overrides(code_block_3) == (true, ["Main.qux", "sin"])
end