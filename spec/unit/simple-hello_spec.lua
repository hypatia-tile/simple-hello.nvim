describe("simple-hello module #unit", function()
   local simple_hello

   before_each(function()
      -- Reload module for each test to ensure clean state
      package.loaded["simple-hello"] = nil
      simple_hello = require("simple-hello")
   end)

   describe("module structure", function()
      it("can be required", function()
         assert.is_not_nil(simple_hello)
      end)

      it("is a table", function()
         assert.is_table(simple_hello)
      end)

      it("has hello function", function()
         assert.is_function(simple_hello.hello)
      end)
   end)

   describe("hello function", function()
      it("executes without error", function()
         assert.has_no.errors(function()
            simple_hello.hello()
         end)
      end)

      it("calls print with message", function()
         -- Spy on global print function
         local print_spy = spy.on(_G, "print")

         simple_hello.hello()

         -- Verify print was called
         assert.spy(print_spy).was_called()
         assert.spy(print_spy).was_called(1)  -- exactly once

         -- Verify the message contains expected text
         local call_args = print_spy.calls[1].vals
         assert.is_string(call_args[1])
         assert.matches("Hello", call_args[1])
         assert.matches("simple%-hello", call_args[1])

         -- Restore original print
         print_spy:revert()
      end)

      it("prints expected message format", function()
         local captured = nil
         local original_print = _G.print

         -- Mock print to capture output
         _G.print = function(msg)
            captured = msg
         end

         simple_hello.hello()

         -- Restore original print
         _G.print = original_print

         -- Verify captured message
         assert.is_not_nil(captured)
         assert.equals("Hello, from simple-hello.lua!", captured)
      end)
   end)
end)
